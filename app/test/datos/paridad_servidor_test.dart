import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/remoto/servicio_cuenta_remoto.dart';
import 'package:moca/datos/repositorios/repositorio_informe_local.dart';
import 'package:moca/datos/repositorios/repositorio_moca_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/simulados/demo.dart';
import 'package:moca/dominio/cifras.dart';
import 'package:moca/dominio/cuenta_real.dart';
import 'package:moca/dominio/informe.dart';

/// Las cifras de la Demo calculadas en el teléfono, en varios momentos, para
/// comprobar que el servidor calcula lo mismo (servidor/test/cifras.test.ts).
/// Las horas son las del Perú: corre con TZ=America/Lima.
///
/// La prueba carga en el teléfono los datos del archivo y comprueba que
/// calcula las mismas cifras. Para rehacer el archivo tras cambiar una regla:
///   TZ=America/Lima MOCA_PARIDAD_ESCRIBIR=1 flutter test test/datos/paridad_servidor_test.dart
const _archivo = '../servidor/test/paridad/demo.json';

class _Llavero implements Llavero {
  String? llave;

  @override
  Future<String?> leer() async => llave;

  @override
  Future<void> guardar(String nueva) async => llave = nueva;
}

/// Lo que calculan los repositorios del teléfono, en el formato del servidor.
Future<Cifras> _cifrasLocales(BaseLocal base, DateTime ahora) async {
  DateTime reloj() => ahora;
  final inicio = await RepositorioMovimientosLocal(
    base,
    ahora: reloj,
  ).observarInicio().first;
  final moca = RepositorioMocaLocal(base, ahora: reloj);
  final informe = RepositorioInformeLocal(base, ahora: reloj);
  final informes = <InformeMes>[await informe.calcularMes(null)];
  for (var previo = informes.first.mesPrevio; previo != null;) {
    informes.insert(0, await informe.calcularMes(previo));
    previo = informes.first.mesPrevio;
  }
  return Cifras(
    dia: Cifras.textoDia(ahora),
    saldos: inicio.saldosPorCuenta,
    inicio: CifrasInicio(
      semanaEntroCentimos: inicio.semanaEntroCentimos,
      semanaSalioCentimos: inicio.semanaSalioCentimos,
      semanaConMovimientos: inicio.semanaConMovimientos,
      diferenciaConSemanaAnteriorCentimos:
          inicio.diferenciaConSemanaAnteriorCentimos,
      ventaDeHoyCentimos: inicio.ventaDeHoyCentimos,
      estadoArqueo: inicio.estadoArqueo,
    ),
    resumenSemana: await moca.observarResumen().first,
    avisos: await moca.observarAvisos().first,
    informes: informes,
  );
}

void main() {
  final enLima =
      DateTime(2026, 10, 12).timeZoneOffset == const Duration(hours: -5);
  final escribir = Platform.environment['MOCA_PARIDAD_ESCRIBIR'] != null;

  test('Rehace el archivo con la Demo', () async {
    final base = BaseLocal(NativeDatabase.memory());
    addTearDown(base.close);
    final cargada = DateTime(2026, 10, 12, 21, 5);
    await cargarDemo(base, cargada);
    await base
        .into(base.ajustes)
        .insertOnConflictUpdate(
          AjustesCompanion.insert(clave: 'modo', valor: 'real'),
        );

    // Un aviso marcado «Entendido»: el servidor tampoco debe mostrarlo.
    final moca = RepositorioMocaLocal(base, ahora: () => cargada);
    final avisos = await moca.observarAvisos().first;
    await moca.descartar(avisos.firstWhere((a) => a.descartable));

    // Lo que sube el teléfono.
    Map<String, Object?>? subida;
    final servicio = ServicioCuentaRemoto(
      base,
      llavero: _Llavero(),
      ahora: () => cargada,
      cliente: MockClient((pedido) async {
        if (pedido.url.path == '/datos/subir') {
          subida = jsonDecode(
            utf8.decode(gzip.decode(pedido.bodyBytes)),
          ) as Map<String, Object?>;
          return http.Response('{"recibidos":{}}', 200);
        }
        return http.Response(
          jsonEncode({
            'llave': 'llave',
            'usuarioId': 'u',
            'empresas': <String>[],
            'cuentaExistente': false,
          }),
          200,
        );
      }),
    );
    await servicio.verificar('987654321', '123456');
    expect(await servicio.subirTodo(), isTrue);

    // Lunes de noche, mitad de semana, días sin anotar, domingo y otro mes.
    final momentos = [
      cargada,
      DateTime(2026, 10, 14, 10),
      DateTime(2026, 10, 16, 9),
      DateTime(2026, 10, 18, 12),
      DateTime(2026, 11, 3, 9),
    ];
    final archivo = {
      'datos': {
        // Sin la bitácora: no hace falta para las cifras.
        for (final tabla in [
          'empresa',
          'cuentas',
          'contrapartes',
          'comprobantes',
          'items_comprobante',
          'categorias',
          'movimientos',
          'arqueos',
          'arqueo_cuentas',
          'dias_cerrados',
          'alertas',
        ])
          tabla: subida![tabla],
      },
      'momentos': [
        for (final ahora in momentos)
          {
            'ahora': ahora.toUtc().toIso8601String(),
            'cifras': (await _cifrasLocales(base, ahora)).toJson(),
          },
      ],
    };
    File(_archivo)
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '${const JsonEncoder.withIndent(' ').convert(archivo)}\n',
      );
  }, skip: enLima && escribir ? false : 'Solo con MOCA_PARIDAD_ESCRIBIR');

  test(
    'Con los datos del archivo, el teléfono calcula las cifras del archivo',
    () async {
      final archivo =
          jsonDecode(File(_archivo).readAsStringSync()) as Map<String, Object?>;
      final datos = archivo['datos']! as Map<String, Object?>;
      final empresa = datos['empresa']! as Map<String, Object?>;
      final movimientos = datos['movimientos']! as List;
      final usuarioId = (movimientos.first as Map)['autor_id'];

      // Se bajan al teléfono como en «Ya tengo cuenta».
      final base = BaseLocal(NativeDatabase.memory());
      addTearDown(base.close);
      final ahora = DateTime(2026, 10, 12, 21, 5);
      final servicio = ServicioCuentaRemoto(
        base,
        llavero: _Llavero(),
        ahora: () => ahora,
        cliente: MockClient(
          (pedido) async => http.Response(
            jsonEncode(switch (pedido.url.path) {
              '/datos/bajar' => {
                'datos': {
                  ...datos,
                  'usuario': {'id': usuarioId},
                  'membresia': {
                    'id': '00000000-0000-4000-8000-000000000001',
                    'empresa_id': empresa['id'],
                    'rol': 'dueno',
                  },
                },
              },
              _ => {
                'llave': 'llave',
                'usuarioId': usuarioId,
                'empresas': [empresa['id']],
                'cuentaExistente': false,
              },
            }),
            200,
          ),
        ),
      );
      await servicio.verificar('987654321', '123456', entrar: true);
      expect(await servicio.bajarTodo(), ResultadoBajada.listo);

      for (final momento in archivo['momentos']! as List) {
        final m = momento as Map<String, Object?>;
        final cuando = DateTime.parse(m['ahora']! as String).toLocal();
        final esperadas = m['cifras']! as Map<String, Object?>;
        expect(
          jsonDecode(jsonEncode((await _cifrasLocales(base, cuando)).toJson())),
          esperadas,
          reason:
              'Cambió una regla de las cifras (${m['ahora']}): rehaz '
              '$_archivo (ver arriba) y cambia el servidor igual.',
        );
        // Mismo formato de ida y vuelta.
        expect(Cifras.fromJson(esperadas).toJson(), esperadas);
      }
    },
    skip: enLima ? false : 'Corre con TZ=America/Lima',
  );
}
