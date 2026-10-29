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
import 'package:moca/datos/repositorios/repositorio_operador_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/datos/simulados/demo.dart';
import 'package:moca/dominio/cifras.dart';
import 'package:moca/dominio/cuenta_real.dart';
import 'package:moca/dominio/equipo.dart';
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

  /// Lo que responde «/cuenta/negocios» (entrega 22) y de qué negocio se
  /// pidió cada bajada.
  List<Map<String, Object?>>? negocios;
  List<Map<String, Object?>> invitaciones = const [];
  final bajadasPedidas = <String?>[];

  /// Lo que responde «/datos/cambios» (entrega 18) y desde qué cambio se
  /// pidió cada vez.
  Map<String, Object?>? cambios;
  var codigoCambios = 200;
  final pedidosDeCambios = <String?>[];

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
      '/datos/bajar' => () {
        bajadasPedidas.add(pedido.url.queryParameters['empresa']);
        return http.Response(
          jsonEncode({'datos': paraBajar, 'cifras': cifrasDelServidor}),
          200,
        );
      }(),
      '/cuenta/negocios' => http.Response(
        jsonEncode({'negocios': negocios}),
        200,
      ),
      '/cuenta/invitaciones' => http.Response(
        jsonEncode({'invitaciones': invitaciones}),
        200,
      ),
      '/cuenta/aceptar' => http.Response(
        jsonEncode({'empresa_id': (paraBajar!['empresa']! as Map)['id']}),
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
      '/datos/cambios' => () {
        pedidosDeCambios.add(pedido.url.queryParameters['desde']);
        return http.Response(
          jsonEncode(codigoCambios == 200 ? cambios : {'error': 'sin_negocio'}),
          codigoCambios,
        );
      }(),
      '/cifras' => () {
        pedidosDeCifras++;
        return http.Response(jsonEncode({'cifras': cifrasDelServidor}), 200);
      }(),
      _ => http.Response('', 404),
    };
  }

  /// Todo lo que tiene el servidor falso: desde la entrega 18 cada subida
  /// trae solo lo que cambió, y el servidor lo junta por id.
  Map<String, Object?> todoLoSubido() {
    final todo = <String, Object?>{};
    final porTabla = <String, Map<Object?, Object?>>{};
    for (final subida in subidas) {
      for (final MapEntry(key: tabla, value: valor) in subida.entries) {
        if (valor is List) {
          final filas = porTabla.putIfAbsent(tabla, () => {});
          for (final f in valor) {
            filas[(f as Map)['id']] = f;
          }
        } else {
          todo[tabla] = valor;
        }
      }
    }
    for (final MapEntry(key: tabla, value: filas) in porTabla.entries) {
      todo[tabla] = filas.values.toList();
    }
    return todo;
  }

  Future<void> primerDia({
    BaseLocal? en,
    String nombre = 'Bodega Don Lucho',
  }) async {
    final repo = RepositorioPrimerDiaLocal(en ?? base, ahora: () => ahora);
    await repo.anotarPrimeraVenta({TipoCuenta.efectivo: 35000});
    await repo.seguirSinCuenta();
    await repo.completarAlta(
      DatosAlta(
        nombre: nombre,
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
    cambios = null;
    negocios = null;
    invitaciones = const [];
    bajadasPedidas.clear();
    codigoCambios = 200;
    pedidosDeCambios.clear();
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
        'semanaAportesCentimos': 0,
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
          'aportesCentimos': 0,
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
        // Repetir la subida no lo manda otra vez: ya está en el servidor
        // (entrega 18).
        await servicio.subirTodo();
        expect(subidas.last['alertas'], isEmpty);

        final original = AccesoLocal(base, () => ahora);
        final membresia = await base.select(base.membresias).getSingle();
        paraBajar = {
          ...todoLoSubido(),
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
      ...todoLoSubido(),
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
    // Lo que bajó ya está en el servidor: volver a subir no lo repite.
    await otro.subirTodo();
    expect(subidas.last['videos_vistos'], isEmpty);
    expect(visto['id'], isNotNull);
  });

  group('Entrega 18: varias personas, cada una con su teléfono', () {
    late String empresaId;
    late String efectivo;
    late String venta;

    Map<String, Object?> movimiento(
      String id, {
      required String autor,
      int monto = 5000,
      String estado = 'vigente',
    }) => {
      'id': id,
      'tipo': 'ingreso',
      'cuenta_id': efectivo,
      'monto_centimos': monto,
      'fecha_movimiento': ahora.toUtc().toIso8601String(),
      'fecha_comprobante': null,
      'estado_pago': 'pagado',
      'monto_pagado_centimos': monto,
      'fecha_vencimiento': null,
      'fecha_pago': ahora.toUtc().toIso8601String(),
      'categoria_id': venta,
      'contraparte_id': null,
      'comprobante_id': null,
      'nivel_confianza': 'd',
      'fuente': 'voz',
      'autor_id': autor,
      'nota': null,
      'estado': estado,
      'reemplaza_a': null,
      'creado_en': ahora.toUtc().toIso8601String(),
    };

    setUp(() async {
      await primerDia();
      await servicio.verificar('987654321', '123456');
      expect(await servicio.subirTodo(), isTrue);
      empresaId = (await base.select(base.empresas).getSingle()).id;
      efectivo = (await (base.select(
        base.cuentas,
      )..where((c) => c.tipo.equalsValue(TipoCuenta.efectivo))).getSingle()).id;
      venta = (await (base.select(
        base.categorias,
      )..where((c) => c.nombre.equals('Venta del día'))).getSingle()).id;
    });

    test(
      'Después de la primera, cada subida lleva solo lo que cambió',
      () async {
        expect(subidas.single['movimientos'], hasLength(1));
        await RepositorioMovimientosLocal(base, ahora: () => ahora).registrar(
          NuevoMovimiento(
            tipo: TipoMovimiento.ingreso,
            montoCentimos: 2000,
            cuenta: TipoCuenta.efectivo,
            categoriaId: venta,
          ),
        );
        expect(await servicio.subirTodo(), isTrue);
        final segunda = subidas.last;
        expect(segunda['movimientos'], hasLength(1));
        expect(
          (segunda['movimientos']! as List).single,
          containsPair('monto_centimos', 2000),
        );
        expect(segunda['cuentas'], isEmpty);
        expect(segunda['categorias'], isEmpty);
        // La empresa va siempre: el servidor la necesita.
        expect((segunda['empresa']! as Map)['id'], empresaId);
      },
    );

    test('Baja lo de los demás, sin pisar lo que falta subir', () async {
      const pepe = '0f0e0d0c-0000-4000-8000-0000000000aa';
      const deMiTelefono = '0f0e0d0c-0000-4000-8000-0000000000bb';
      // Este teléfono anotó algo que todavía no subió...
      await base
          .into(base.movimientos)
          .insert(
            MovimientosCompanion.insert(
              id: deMiTelefono,
              empresaId: empresaId,
              tipo: TipoMovimiento.ingreso,
              cuentaId: efectivo,
              montoCentimos: 7000,
              fechaMovimiento: ahora,
              estadoPago: EstadoPago.pagado,
              montoPagadoCentimos: 7000,
              categoriaId: Value(venta),
              nivelConfianza: NivelConfianza.d,
              fuente: Fuente.texto,
              autorId: (await base.select(base.usuarios).getSingle()).id,
              estado: EstadoRegistro.vigente,
              estadoSincronizacion: EstadoSincronizacion.porSubir,
              creadoEn: ahora,
            ),
          );
      // ...y del servidor llega la venta de Pepe y otra versión de la suya.
      cambios = {
        'empresa_id': empresaId,
        'rol': 'dueno',
        'titular': true,
        'personas': 2,
        'hasta': 50,
        'movimientos': [
          movimiento('0f0e0d0c-0000-4000-8000-0000000000cc', autor: pepe),
          movimiento(deMiTelefono, autor: pepe, monto: 1),
        ],
      };
      expect(await servicio.traerCambios(), isTrue);
      expect(pedidosDeCambios, ['0']);

      final movimientos = {
        for (final m in await base.select(base.movimientos).get()) m.id: m,
      };
      expect(
        movimientos['0f0e0d0c-0000-4000-8000-0000000000cc']!.autorId,
        pepe,
      );
      expect(movimientos[deMiTelefono]!.montoCentimos, 7000);

      final situacion = await servicio.observar().first;
      expect(situacion.variasPersonas, isTrue);
      expect(situacion.actualizadoEn, ahora);

      // Lo de Pepe no se vuelve a subir; lo propio, sí.
      await servicio.subirTodo();
      final subidos = [
        for (final m in subidas.last['movimientos']! as List) (m as Map)['id'],
      ];
      expect(subidos, [deMiTelefono]);

      // La próxima vez pide desde el cambio 50, y un cambio de Pepe se ve.
      cambios = {
        ...cambios!,
        'hasta': 60,
        'movimientos': [
          movimiento(
            '0f0e0d0c-0000-4000-8000-0000000000cc',
            autor: pepe,
            estado: 'anulado',
          ),
        ],
      };
      await servicio.traerCambios();
      expect(pedidosDeCambios.last, '50');
      final anulado =
          await (base.select(base.movimientos)..where(
                (m) => m.id.equals('0f0e0d0c-0000-4000-8000-0000000000cc'),
              ))
              .getSingle();
      expect(anulado.estado, EstadoRegistro.anulado);
      expect(await servicio.hayCambiosSinSubir(), isFalse);
    });

    test('La venta simulada de Pepe (entrega 20.1) no se sube', () async {
      await RepositorioOperadorLocal(
        base,
        ahora: () => ahora,
      ).simularVentaDeOtro();
      await servicio.subirTodo();
      for (final subida in subidas) {
        for (final m in subida['movimientos']! as List) {
          expect((m as Map)['autor_id'], isNot(AccesoLocal.usuarioSimulado));
        }
      }
    });

    test('Si un dueño lo quita del negocio, deja de subir y lo dice', () async {
      codigoCambios = 403;
      expect(await servicio.traerCambios(), isFalse);
      final situacion = await servicio.observar().first;
      expect(situacion.estado, EstadoCuenta.fueraDelNegocio);
      expect(situacion.mostrarTarjeta, isTrue);
      final antes = subidas.length;
      expect(await servicio.subirTodo(), isFalse);
      expect(subidas, hasLength(antes));
    });
  });

  test('Entrega 22: el contador pasa a ver otro de sus negocios, sin perder '
      'lo que falta subir', () async {
    await primerDia();
    await servicio.verificar('987654321', '123456');
    expect(await servicio.subirTodo(), isTrue);
    final mio = (await base.select(base.empresas).getSingle()).id;

    // El otro negocio, armado en otro teléfono y subido al mismo servidor.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final otraBase = BaseLocal(NativeDatabase.memory());
    addTearDown(otraBase.close);
    await primerDia(en: otraBase, nombre: 'Pollería Rosa');
    final otro = ServicioCuentaRemoto(
      otraBase,
      llavero: _Llavero(),
      cliente: MockClient(servidor),
      ahora: () => ahora,
    );
    await otro.verificar('912345678', '123456');
    await otro.subirTodo();
    final rosa = (await otraBase.select(otraBase.empresas).getSingle()).id;
    final yo = await AccesoLocal(base, () => ahora).usuario();
    paraBajar = {
      ...subidas.last,
      'usuario': {'id': yo.id, 'celular': '+51987654321'},
      'membresia': {
        'id': '0f0e0d0c-0000-4000-8000-0000000000dd',
        'empresa_id': rosa,
        'rol': 'contador',
      },
      'hasta': 70,
    };
    negocios = [
      {'empresa_id': mio, 'nombre': 'Bodega Don Lucho', 'rol': 'dueno'},
      {'empresa_id': rosa, 'nombre': 'Pollería Rosa', 'rol': 'contador'},
    ];

    final lista = (await servicio.misNegocios())!;
    expect(lista.map((n) => (n.nombre, n.rol, n.actual)), [
      ('Bodega Don Lucho', Rol.dueno, true),
      ('Pollería Rosa', Rol.contador, false),
    ]);

    // Algo de este teléfono que falta subir...
    final venta = (await (base.select(
      base.categorias,
    )..where((c) => c.nombre.equals('Venta del día'))).getSingle()).id;
    await RepositorioMovimientosLocal(base, ahora: () => ahora).registrar(
      NuevoMovimiento(
        tipo: TipoMovimiento.ingreso,
        montoCentimos: 4200,
        cuenta: TipoCuenta.efectivo,
        categoriaId: venta,
      ),
    );
    final antes = subidas.length;
    expect(await servicio.cambiarDeNegocio(rosa), ResultadoEquipo.listo);
    // ...sube antes de que se reemplace.
    expect(subidas.length, antes + 1);
    expect(
      (subidas[antes]['movimientos']! as List).map(
        (m) => (m as Map)['monto_centimos'],
      ),
      contains(4200),
    );
    expect(bajadasPedidas.last, rosa);

    final acceso = AccesoLocal(base, () => ahora);
    expect((await acceso.empresa())!.nombre, 'Pollería Rosa');
    expect(await acceso.miRol(), Rol.contador);
    expect(await servicio.hayCambiosSinSubir(), isFalse);
    // Lo que sigue se pide de ese negocio, desde donde quedó la bajada.
    cambios = {'empresa_id': rosa, 'rol': 'contador', 'hasta': 70};
    await servicio.traerCambios();
    expect(pedidosDeCambios.last, '70');
  });

  test('Entrega 22.1: a quien quitaron acepta otra invitación sin borrar '
      'todo', () async {
    await primerDia();
    await servicio.verificar('987654321', '123456');
    expect(await servicio.subirTodo(), isTrue);
    final empresa = (await base.select(base.empresas).getSingle()).id;
    final yo = await AccesoLocal(base, () => ahora).usuario();

    // Un dueño lo quitó; lo que anote desde ahora no sube.
    codigoCambios = 403;
    await servicio.traerCambios();
    expect(
      (await servicio.observar().first).estado,
      EstadoCuenta.fueraDelNegocio,
    );
    final venta = (await (base.select(
      base.categorias,
    )..where((c) => c.nombre.equals('Venta del día'))).getSingle()).id;
    await RepositorioMovimientosLocal(base, ahora: () => ahora).registrar(
      NuevoMovimiento(
        tipo: TipoMovimiento.ingreso,
        montoCentimos: 900,
        cuenta: TipoCuenta.efectivo,
        categoriaId: venta,
      ),
    );

    // Lo vuelven a invitar, ahora como ayudante.
    invitaciones = [
      {
        'id': 'inv',
        'negocio': 'Bodega Don Lucho',
        'rol': 'ayudante',
        'vence_en': ahora.add(const Duration(days: 7)).toIso8601String(),
      },
    ];
    negocios = const [];
    expect(await servicio.misNegocios(), isEmpty);
    final recibidas = (await servicio.buscarInvitaciones())!;
    expect(recibidas.single.rol, Rol.ayudante);

    paraBajar = {
      ...todoLoSubido(),
      'usuario': {'id': yo.id, 'celular': '+51987654321'},
      'membresia': {
        'id': '0f0e0d0c-0000-4000-8000-0000000000ee',
        'empresa_id': empresa,
        'rol': 'ayudante',
      },
    };
    final antes = subidas.length;
    expect(await servicio.aceptar('inv'), ResultadoEquipo.listo);
    // Lo anotado mientras estaba fuera no sube: el servidor lo rechazaría.
    expect(subidas, hasLength(antes));
    expect(bajadasPedidas.last, empresa);
    expect((await servicio.observar().first).estado, EstadoCuenta.guardada);
    expect(await AccesoLocal(base, () => ahora).miRol(), Rol.ayudante);
  });
}
