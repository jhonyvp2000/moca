import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/remoto/servicio_cuenta_remoto.dart';
import 'package:moca/datos/repositorios/acceso_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/datos/simulados/demo.dart';
import 'package:moca/dominio/cuenta_real.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/primer_dia.dart';

class _Llavero implements Llavero {
  String? llave;

  @override
  Future<String?> leer() async => llave;

  @override
  Future<void> guardar(String nueva) async => llave = nueva;
}

void main() {
  late BaseLocal base;
  late _Llavero llavero;
  late List<Map<String, Object?>> subidas;
  late ServicioCuentaRemoto servicio;
  final ahora = DateTime(2026, 10, 12, 21, 5);

  Future<http.Response> servidor(http.Request pedido) async {
    final cuerpo = jsonDecode(pedido.body) as Map<String, Object?>;
    return switch (pedido.url.path) {
      '/cuenta/verificar' => http.Response(
        jsonEncode({
          'llave': 'llave',
          'usuarioId': cuerpo['usuarioId'],
          'empresas': <String>[],
          'cuentaExistente': false,
        }),
        200,
      ),
      '/datos/subir' => () {
        subidas.add(cuerpo);
        return http.Response('{"recibidos":{}}', 200);
      }(),
      _ => http.Response('', 404),
    };
  }

  Future<void> primerDia() async {
    final repo = RepositorioPrimerDiaLocal(base, ahora: () => ahora);
    await repo.anotarPrimeraVenta({TipoCuenta.efectivo: 35000});
    await repo.seguirSinCuenta();
    await repo.completarAlta(
      const DatosAlta(
        nombre: 'Bodega Don Lucho',
        tipoNegocio: TipoNegocio.bodega,
        saldos: {TipoCuenta.efectivo: 100000},
        horaCierreMinutos: 21 * 60,
      ),
    );
  }

  setUp(() {
    base = BaseLocal(NativeDatabase.memory());
    llavero = _Llavero();
    subidas = [];
    servicio = ServicioCuentaRemoto(
      base,
      llavero: llavero,
      cliente: MockClient(servidor),
      ahora: () => ahora,
    );
  });

  tearDown(() => base.close());

  test('Sin cuenta no se sube nada', () async {
    await primerDia();
    expect(await servicio.subirTodo(), isFalse);
    expect(subidas, isEmpty);
  });

  test('Sube en el formato del servidor y marca lo subido', () async {
    await primerDia();
    expect(
      await servicio.verificar('987654321', '123456'),
      ResultadoVerificacion.verificado,
    );
    expect(await servicio.hayCambiosSinSubir(), isTrue);
    expect(await servicio.subirTodo(), isTrue);

    final datos = subidas.single;
    final empresa = datos['empresa']! as Map;
    expect(empresa['tipo_negocio'], 'bodega');
    expect(empresa['hora_cierre_minutos'], 1260);
    final venta = (datos['movimientos']! as List).single as Map;
    expect(venta['monto_centimos'], 35000);
    expect(venta['nivel_confianza'], 'd');
    // Las fechas van en UTC, con la «Z», y marcan el mismo instante.
    final fecha = venta['fecha_movimiento']! as String;
    expect(fecha, endsWith('Z'));
    expect(DateTime.parse(fecha).isAtSameMomentAs(ahora), isTrue);
    expect((datos['cuentas']! as List).map((c) => (c as Map)['tipo']), [
      'efectivo',
      'yape',
      'banco',
    ]);
    // La bitácora va como JSON, no como texto.
    final bitacora = datos['bitacora']! as List;
    expect((bitacora.first as Map)['valor_nuevo'], isA<Map>());

    final movimientos = await base.select(base.movimientos).get();
    expect(
      movimientos.map((m) => m.estadoSincronizacion),
      everyElement(EstadoSincronizacion.subido),
    );
    expect(await servicio.hayCambiosSinSubir(), isFalse);

    // Con cuenta, lo nuevo queda por subir hasta que se sube.
    expect(
      await AccesoLocal(base, () => ahora).estadoAlGuardar(),
      EstadoSincronizacion.porSubir,
    );
  });

  test('Un día cerrado va como fecha sin hora', () async {
    await primerDia();
    final empresa = (await AccesoLocal(base, () => ahora).empresa())!;
    await base
        .into(base.diasCerrados)
        .insert(
          DiasCerradosCompanion.insert(
            id: '6f1c3e1a-0000-4000-8000-000000000001',
            empresaId: empresa.id,
            dia: DateTime(2026, 10, 11),
          ),
        );
    await servicio.verificar('987654321', '123456');
    await servicio.subirTodo();
    expect(subidas.single['dias_cerrados'], [
      {'id': '6f1c3e1a-0000-4000-8000-000000000001', 'dia': '2026-10-11'},
    ]);
  });

  test('En la Demo no se sube nada ni aparece la tarjeta', () async {
    await cargarDemo(base, ahora);
    await base
        .into(base.ajustes)
        .insertOnConflictUpdate(
          AjustesCompanion.insert(
            clave: AccesoLocal.claveCuentaVerificada,
            valor: '987654321',
          ),
        );
    llavero.llave = 'llave';
    expect(await servicio.subirTodo(), isFalse);
    expect(subidas, isEmpty);
  });

  test('La tarjeta: confirmar el número o, a los 3 días, guardar', () async {
    await primerDia();
    expect((await servicio.observar().first).mostrarTarjeta, isFalse);
    final despues = ServicioCuentaRemoto(
      base,
      llavero: llavero,
      cliente: MockClient(servidor),
      ahora: () => ahora.add(const Duration(days: 3)),
    );
    final situacion = await despues.observar().first;
    expect(situacion.estado, EstadoCuenta.sinCuenta);
    expect(situacion.mostrarTarjeta, isTrue);

    await base
        .update(base.usuarios)
        .write(const UsuariosCompanion(celular: Value('912345678')));
    final porConfirmar = await servicio.observar().first;
    expect(porConfirmar.estado, EstadoCuenta.porConfirmar);
    expect(porConfirmar.celular, '912345678');
    expect(porConfirmar.mostrarTarjeta, isTrue);
  });

  // Deja la subida de la Demo en un archivo para comprobar, aparte, que el
  // servidor de verdad la acepta (MOCA_SUBIDA_DEMO=ruta).
  test('Subida de la Demo completa', () async {
    await cargarDemo(base, ahora);
    await base
        .into(base.ajustes)
        .insertOnConflictUpdate(
          AjustesCompanion.insert(clave: 'modo', valor: 'real'),
        );
    await servicio.verificar('987654321', '123456');
    expect(await servicio.subirTodo(), isTrue);
    final datos = subidas.single;
    expect((datos['movimientos']! as List).length, greaterThan(100));
    final ruta = Platform.environment['MOCA_SUBIDA_DEMO'];
    if (ruta != null) {
      final usuario = (await base.select(base.usuarios).getSingle()).id;
      File(
        ruta,
      ).writeAsStringSync(jsonEncode({'usuarioId': usuario, 'datos': datos}));
    }
  });
}
