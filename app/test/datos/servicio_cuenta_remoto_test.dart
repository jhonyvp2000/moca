import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/dominio/tutoria.dart';
import 'package:moca/dominio/medicion.dart';
import 'package:moca/datos/repositorios/medicion_local.dart';
import 'package:moca/datos/repositorios/repositorio_tutoria_local.dart';
import 'package:moca/datos/remoto/servicio_cuenta_remoto.dart';
import 'package:moca/datos/repositorios/acceso_local.dart';
import 'package:moca/datos/repositorios/repositorio_informe_local.dart';
import 'package:moca/datos/repositorios/repositorio_moca_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/datos/simulados/demo.dart';
import 'package:moca/dominio/cifras.dart';
import 'package:moca/dominio/cuenta_real.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/movimientos.dart';
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

  Map<String, Object?>? paraBajar;

  /// Las cifras que responde el servidor (entrega 13), y cuántas veces se
  /// pidieron aparte.
  Map<String, Object?>? cifrasDelServidor;
  var pedidosDeCifras = 0;

  Future<http.Response> servidor(http.Request pedido) async {
    final bytes = pedido.headers['Content-Encoding'] == 'gzip'
        ? gzip.decode(pedido.bodyBytes)
        : pedido.bodyBytes;
    final cuerpo = bytes.isEmpty
        ? const <String, Object?>{}
        : jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
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
      '/datos/bajar' => http.Response(
        jsonEncode({'datos': paraBajar, 'cifras': cifrasDelServidor}),
        200,
      ),
      '/datos/subir' => () {
        subidas.add(cuerpo);
        return http.Response(
          jsonEncode({
            'recibidos': <String, int>{},
            'cifras': cifrasDelServidor,
          }),
          200,
        );
      }(),
      '/cifras' => () {
        pedidosDeCifras++;
        return http.Response(jsonEncode({'cifras': cifrasDelServidor}), 200);
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
    cifrasDelServidor = null;
    pedidosDeCifras = 0;
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

  test(
    'Otro teléfono baja la Demo y queda igual: saldos, historial y etapa',
    () async {
      await cargarDemo(base, ahora);
      await base
          .into(base.ajustes)
          .insertOnConflictUpdate(
            AjustesCompanion.insert(clave: 'modo', valor: 'real'),
          );
      await servicio.verificar('987654321', '123456');
      expect(await servicio.subirTodo(), isTrue);
      final subida = subidas.single;
      final original = AccesoLocal(base, () => ahora);
      final empresa = (await original.empresa())!;
      final usuario = await original.usuario();
      final membresia = await base.select(base.membresias).getSingle();
      // Lo que el servidor devuelve: lo subido, más el usuario y su membresía.
      paraBajar = {
        ...subida,
        'usuario': {'id': usuario.id, 'celular': '+51987654321'},
        'membresia': {
          'id': membresia.id,
          'empresa_id': empresa.id,
          'rol': 'dueno',
        },
      };

      // Dos teléfonos, dos bases: a propósito.
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final otraBase = BaseLocal(NativeDatabase.memory());
      addTearDown(otraBase.close);
      final otro = ServicioCuentaRemoto(
        otraBase,
        llavero: _Llavero(),
        cliente: MockClient(servidor),
        ahora: () => ahora,
      );
      expect(
        await otro.verificar('987654321', '123456', entrar: true),
        ResultadoVerificacion.verificado,
      );
      expect(await otro.bajarTodo(), ResultadoBajada.listo);

      final copia = AccesoLocal(otraBase, () => ahora);
      expect(await copia.saldos(empresa.id), await original.saldos(empresa.id));
      expect(
        (await otraBase.select(otraBase.movimientos).get()).length,
        (await base.select(base.movimientos).get()).length,
      );
      expect(
        (await otraBase.select(otraBase.bitacora).get()).length,
        (await base.select(base.bitacora).get()).length,
      );
      expect(await copia.leerAjuste('etapa'), 'listo');
      expect(
        await copia.leerAjuste(AccesoLocal.claveCuentaVerificada),
        '987654321',
      );
      // Lo que bajó ya está en el servidor: no hay nada que subir.
      expect(await otro.hayCambiosSinSubir(), isFalse);
      expect((await otro.observar().first).estado, EstadoCuenta.guardada);
    },
  );

  test(
    'Si el servidor rechaza la llave, la cuenta se abrió en otro teléfono',
    () async {
      await primerDia();
      await servicio.verificar('987654321', '123456');
      llavero.llave = 'llave-revocada';
      final cerrado = ServicioCuentaRemoto(
        base,
        llavero: llavero,
        cliente: MockClient(
          (pedido) async => http.Response('{"error":"sin_sesion"}', 401),
        ),
        ahora: () => ahora,
      );
      expect(await cerrado.subirTodo(), isFalse);
      final situacion = await cerrado.observar().first;
      expect(situacion.estado, EstadoCuenta.cerradaEnOtro);
      expect(situacion.mostrarTarjeta, isTrue);
    },
  );

  group('Entrega 13: cifras del servidor', () {
    /// Cifras distintas de las del teléfono, para saber de dónde salen.
    Map<String, Object?> cifras({required int efectivo, DateTime? dia}) => {
      'dia': Cifras.textoDia(dia ?? ahora),
      'saldos': {'efectivo': efectivo, 'yape': 0, 'banco': 0},
      'inicio': {
        'semanaEntroCentimos': 777700,
        'semanaSalioCentimos': 0,
        'semanaRetirosCentimos': 0,
        'semanaConMovimientos': true,
        'diferenciaConSemanaAnteriorCentimos': null,
        'ventaDeHoyCentimos': 35000,
        'estadoArqueo': 'nada',
      },
      'resumenSemana': {
        'semanaPasada': false,
        'conMovimientos': true,
        'quedoCentimos': 777700,
        'diferenciaCentimos': null,
        'categoriaTop': null,
        'categoriaTopCentimos': null,
      },
      'avisos': <Object>[],
      'informes': [
        {
          'mes': '2026-10',
          'enCurso': true,
          'sinRegistros': false,
          'desdeDia': 12,
          'mesAnterior': null,
          'diferenciaConAnteriorCentimos': null,
          'entroCentimos': 777700,
          'salioCentimos': 0,
          'retirosCentimos': 0,
          'inicioCentimos': 0,
          'ajustesCentimos': 0,
          'gastos': <Object>[],
          'cambio': null,
          'loQueDebesCentimos': 0,
          'confianza': null,
          'advertenciaMercaderia': false,
          'mesPrevio': null,
          'mesSiguiente': null,
        },
      ],
    };

    Future<ResumenInicio> inicio([DateTime? cuando]) =>
        RepositorioMovimientosLocal(
          base,
          ahora: () => cuando ?? ahora,
        ).observarInicio().first;

    test('Con todo subido, el Inicio, Moca y el informe muestran las del '
        'servidor', () async {
      await primerDia();
      await servicio.verificar('987654321', '123456');
      cifrasDelServidor = cifras(efectivo: 999900);
      expect(await servicio.subirTodo(), isTrue);

      final resumen = await inicio();
      expect(resumen.saldosPorCuenta[TipoCuenta.efectivo], 999900);
      expect(resumen.semanaEntroCentimos, 777700);
      final semana = await RepositorioMocaLocal(
        base,
        ahora: () => ahora,
      ).observarResumen().first;
      expect(semana.quedoCentimos, 777700);
      final informe = await RepositorioInformeLocal(
        base,
        ahora: () => ahora,
      ).observarMes(DateTime(2026, 9)).first;
      expect(informe.entroCentimos, 777700);
      expect(informe.mes, DateTime(2026, 10));
    });

    test(
      'Con algo por subir o al día siguiente, calcula el teléfono',
      () async {
        await primerDia();
        await servicio.verificar('987654321', '123456');
        cifrasDelServidor = cifras(efectivo: 999900);
        await servicio.subirTodo();
        // Saldo inicial de S/ 1,000 más la venta de S/ 350.
        const delTelefono = 135000;

        // Al día siguiente ya no valen.
        expect(
          (await inicio(ahora.add(const Duration(days: 1))))
              .saldosPorCuenta[TipoCuenta.efectivo],
          delTelefono,
        );

        // Sin señal, un cambio queda por subir: las cifras del servidor no lo
        // tienen.
        final empresa = (await AccesoLocal(base, () => ahora).empresa())!;
        await base
            .into(base.diasCerrados)
            .insert(
              DiasCerradosCompanion.insert(
                id: '6f1c3e1a-0000-4000-8000-000000000002',
                empresaId: empresa.id,
                dia: DateTime(2026, 10, 11),
              ),
            );
        expect(
          (await inicio()).saldosPorCuenta[TipoCuenta.efectivo],
          delTelefono,
        );
        // Al subir llegan las nuevas.
        cifrasDelServidor = cifras(efectivo: 888800);
        await servicio.subirTodo();
        expect((await inicio()).saldosPorCuenta[TipoCuenta.efectivo], 888800);
      },
    );

    test('Las pide solo si las del teléfono no valen', () async {
      await primerDia();
      await servicio.verificar('987654321', '123456');
      await servicio.subirTodo();
      cifrasDelServidor = cifras(efectivo: 999900);

      await servicio.actualizarCifras();
      expect(pedidosDeCifras, 1);
      expect((await inicio()).saldosPorCuenta[TipoCuenta.efectivo], 999900);
      await servicio.actualizarCifras();
      expect(pedidosDeCifras, 1);
    });

    test('Las de un servidor sin actualizar se descartan: calcula el '
        'teléfono (entrega 14.9)', () async {
      await primerDia();
      await servicio.verificar('987654321', '123456');
      await servicio.subirTodo();
      final anteriores = cifras(efectivo: 999900);
      (anteriores['informes']! as List).cast<Map<String, Object?>>().first
        ..remove('inicioCentimos')
        ..remove('ajustesCentimos');
      cifrasDelServidor = anteriores;
      await servicio.actualizarCifras();
      expect(
        (await inicio()).saldosPorCuenta[TipoCuenta.efectivo],
        isNot(999900),
      );
    });

    test('Sin cuenta o en la Demo no se piden', () async {
      await primerDia();
      await servicio.actualizarCifras();
      expect(pedidosDeCifras, 0);
    });

    test(
      'Un aviso marcado «Entendido» sube y baja en el otro teléfono',
      () async {
        await cargarDemo(base, ahora);
        await base
            .into(base.ajustes)
            .insertOnConflictUpdate(
              AjustesCompanion.insert(clave: 'modo', valor: 'real'),
            );
        await servicio.verificar('987654321', '123456');
        await servicio.subirTodo();
        final moca = RepositorioMocaLocal(base, ahora: () => ahora);
        final aviso = (await moca.observarAvisos().first).firstWhere(
          (a) => a.descartable,
        );
        await moca.descartar(aviso);
        expect(await servicio.hayCambiosSinSubir(), isTrue);
        await servicio.subirTodo();
        final alertas = subidas.last['alertas']! as List;
        final subida = alertas.single as Map;
        expect(subida['clave'], aviso.clave);
        expect(subida['estado'], 'vista');
        // El mismo id cada vez: repetir la subida no duplica.
        await servicio.subirTodo();
        expect(
          ((subidas.last['alertas']! as List).single as Map)['id'],
          subida['id'],
        );

        final original = AccesoLocal(base, () => ahora);
        final membresia = await base.select(base.membresias).getSingle();
        paraBajar = {
          ...subidas.last,
          'usuario': {'id': (await original.usuario()).id},
          'membresia': {
            'id': membresia.id,
            'empresa_id': membresia.empresaId,
            'rol': 'dueno',
          },
        };
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
        final otraBase = BaseLocal(NativeDatabase.memory());
        addTearDown(otraBase.close);
        final otro = ServicioCuentaRemoto(
          otraBase,
          llavero: _Llavero(),
          cliente: MockClient(servidor),
          ahora: () => ahora,
        );
        await otro.verificar('987654321', '123456', entrar: true);
        expect(await otro.bajarTodo(), ResultadoBajada.listo);
        final avisos = await RepositorioMocaLocal(
          otraBase,
          ahora: () => ahora,
        ).observarAvisos().first;
        expect(avisos.map((a) => a.clave), isNot(contains(aviso.clave)));
        expect(await otro.hayCambiosSinSubir(), isFalse);
      },
    );
  });

  test('Entrega 14.6: los videos vistos se suben y vuelven al entrar en '
      'otro teléfono', () async {
    await primerDia();
    await servicio.verificar('987654321', '123456');
    await RepositorioTutoriaLocal(
      base,
      ahora: () => ahora,
    ).marcarVisto(VideoTutoria.arqueo, DesdeVideo.aprende);
    await MedicionLocal(
      base,
      ahora: () => ahora,
    ).anotar(EventoMedicion.appAbierta);
    await servicio.subirTodo();

    // Solo los videos: el resto de la medición se queda en el teléfono.
    final videos = subidas.last['videos_vistos']! as List;
    final visto = videos.single as Map;
    expect(visto['video'], 5);
    expect(visto['desde'], 'aprende');
    expect(visto['fecha'], endsWith('Z'));

    final membresia = await base.select(base.membresias).getSingle();
    paraBajar = {
      ...subidas.last,
      'usuario': {'id': (await AccesoLocal(base, () => ahora).usuario()).id},
      'membresia': {
        'id': membresia.id,
        'empresa_id': membresia.empresaId,
        'rol': 'dueno',
      },
    };
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final otraBase = BaseLocal(NativeDatabase.memory());
    addTearDown(otraBase.close);
    final otro = ServicioCuentaRemoto(
      otraBase,
      llavero: _Llavero(),
      cliente: MockClient(servidor),
      ahora: () => ahora,
    );
    await otro.verificar('987654321', '123456', entrar: true);
    expect(await otro.bajarTodo(), ResultadoBajada.listo);
    final estado = await RepositorioTutoriaLocal(otraBase).observar().first;
    expect(estado.vistos, {VideoTutoria.arqueo});
    // Con el mismo id: volver a subir no lo repite en el servidor.
    await otro.subirTodo();
    expect(
      ((subidas.last['videos_vistos']! as List).single as Map)['id'],
      visto['id'],
    );
  });
}
