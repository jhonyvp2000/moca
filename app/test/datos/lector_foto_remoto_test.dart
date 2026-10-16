import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/remoto/lector_foto_remoto.dart';
import 'package:moca/datos/repositorios/acceso_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/dominio/comprobantes.dart';
import 'package:moca/dominio/cuenta_real.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/primer_dia.dart';

class _Llavero implements Llavero {
  String? llave = 'llave';

  @override
  Future<String?> leer() async => llave;

  @override
  Future<void> guardar(String nueva) async => llave = nueva;
}

class _BuscadorQr implements BuscadorQr {
  String? contenido;

  @override
  Future<String?> buscar(String rutaImagen) async => contenido;
}

class _DeEjemplo implements LectorFoto {
  var usado = false;

  @override
  Future<ResultadoLectura> leer(String rutaImagen) async {
    usado = true;
    return const FotoLeida(LecturaComprobante(origen: OrigenLectura.foto));
  }
}

void main() {
  final ahora = DateTime(2026, 10, 14, 12);
  late BaseLocal base;
  late _Llavero llavero;
  late _BuscadorQr qr;
  late _DeEjemplo deEjemplo;
  late List<http.Request> pedidos;
  late http.Response Function() responder;
  var conSenal = true;

  LectorFotoRemoto lector() => LectorFotoRemoto(
    base,
    llavero: llavero,
    buscadorQr: qr,
    deEjemplo: deEjemplo,
    ahora: () => ahora,
    hayConexion: () async => conSenal,
    leerArchivo: (ruta) async => utf8.encode('foto de $ruta'),
    cliente: MockClient((pedido) async {
      pedidos.add(pedido);
      return responder();
    }),
  );

  http.Response leido(String resultado, [Map<String, Object?>? lectura]) =>
      http.Response(
        jsonEncode({'resultado': resultado, 'lectura': lectura}),
        200,
      );

  const factura = {
    'emisor_identificacion': '20100070970',
    'emisor_nombre': 'Distribuidora San Martín',
    'tipo': 'Factura',
    'serie': 'F001',
    'numero': '245',
    'fecha_emision': '2026-10-13',
    'impuesto_centimos': 1495,
    'total_centimos': 9800,
    'cantidad_items': 12,
    'categoria': 'Mercadería',
  };

  setUp(() async {
    base = BaseLocal(NativeDatabase.memory());
    llavero = _Llavero();
    qr = _BuscadorQr();
    deEjemplo = _DeEjemplo();
    pedidos = [];
    conSenal = true;
    responder = () => leido('leido', factura);
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
    await AccesoLocal(
      base,
      () => ahora,
    ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321');
  });

  tearDown(() => base.close());

  test('Con el QR en la foto, lee el QR y no gasta en la IA', () async {
    qr.contenido = '20100070970|01|F001|00000245|14.95|98.00|2026-10-13|6|1|';
    final resultado = await lector().leer('/foto.jpg');
    final lectura = (resultado as FotoLeida).lectura;
    expect(lectura.origen, OrigenLectura.qr);
    expect(lectura.totalCentimos, 9800);
    expect(lectura.rutaImagen, '/foto.jpg');
    expect(pedidos, isEmpty);
  });

  test('Sin QR, la lee el servidor con las categorías de gasto', () async {
    qr.contenido = 'https://no-es-un-comprobante.pe';
    final resultado = await lector().leer('/foto.jpg');
    final lectura = (resultado as FotoLeida).lectura;
    expect(lectura.legible, isTrue);
    expect(lectura.origen, OrigenLectura.foto);
    expect(lectura.emisorNombre, 'Distribuidora San Martín');
    expect(lectura.fechaEmision, DateTime(2026, 10, 13));
    expect(lectura.totalCentimos, 9800);
    expect(lectura.categoria, 'Mercadería');

    final pedido = pedidos.single;
    expect(pedido.url.path, '/comprobantes/leer');
    expect(pedido.headers['Authorization'], 'Bearer llave');
    final cuerpo = jsonDecode(pedido.body) as Map<String, Object?>;
    expect(
      utf8.decode(base64Decode(cuerpo['imagen']! as String)),
      'foto de /foto.jpg',
    );
    expect(cuerpo['categorias'], contains('Mercadería'));
    expect(cuerpo['categorias'], isNot(contains('Venta del día')));
  });

  test(
    'Lo que no cuadra llega como foto ilegible, con lo que sí se leyó',
    () async {
      responder = () => leido('ilegible', {...factura, 'total_centimos': null});
      final lectura = ((await lector().leer('/foto.jpg')) as FotoLeida).lectura;
      expect(lectura.legible, isFalse);
      expect(lectura.totalCentimos, isNull);
      expect(lectura.emisorNombre, 'Distribuidora San Martín');
    },
  );

  test('Cada problema tiene su respuesta', () async {
    Future<ProblemaLectura> problema() async =>
        ((await lector().leer('/foto.jpg')) as FotoNoLeida).problema;

    responder = () => leido('no_es_comprobante');
    expect(await problema(), ProblemaLectura.noEsComprobante);
    responder = () => http.Response('{"error":"limite_diario"}', 429);
    expect(await problema(), ProblemaLectura.limiteDiario);
    responder = () => http.Response('{"error":"no_se_pudo_leer"}', 502);
    expect(await problema(), ProblemaLectura.sinSenal);
    responder = () => throw http.ClientException('sin red');
    expect(await problema(), ProblemaLectura.sinSenal);

    pedidos.clear();
    conSenal = false;
    expect(await problema(), ProblemaLectura.sinSenal);
    expect(pedidos, isEmpty);
  });

  group('Sin cuenta, fotos de prueba (entrega 14.2)', () {
    setUp(() async {
      await (base.delete(
        base.ajustes,
      )..where((a) => a.clave.equals(AccesoLocal.claveCuentaVerificada))).go();
      llavero.llave = null;
    });

    http.Response deprueba(int restantes) => http.Response(
      jsonEncode({
        'resultado': 'leido',
        'lectura': factura,
        'pruebasRestantes': restantes,
      }),
      200,
    );

    test('Lee con la ruta de prueba, sin llave, y dice cuál fue', () async {
      final acceso = AccesoLocal(base, () => ahora);
      expect(await acceso.fotosDePrueba(), 3);
      responder = () => deprueba(2);
      final lectura = ((await lector().leer('/foto.jpg')) as FotoLeida).lectura;
      expect(lectura.fotoDePrueba, 1);
      expect(lectura.totalCentimos, 9800);
      final pedido = pedidos.single;
      expect(pedido.url.path, '/comprobantes/leer-prueba');
      expect(pedido.headers.containsKey('Authorization'), isFalse);
      final cuerpo = jsonDecode(pedido.body) as Map<String, Object?>;
      expect(cuerpo['telefono'], (await acceso.usuario()).id);
      expect(await acceso.fotosDePrueba(), 2);
    });

    test('Sin pruebas, no llama al servidor', () async {
      responder = () => deprueba(0);
      await lector().leer('/foto.jpg');
      pedidos.clear();
      final resultado = await lector().leer('/otra.jpg');
      expect(
        (resultado as FotoNoLeida).problema,
        ProblemaLectura.pruebasAgotadas,
      );
      expect(pedidos, isEmpty);
    });

    test('Si el servidor dice que se agotaron, se agotaron', () async {
      responder = () => http.Response('{"error":"pruebas_agotadas"}', 429);
      final resultado = await lector().leer('/foto.jpg');
      expect(
        (resultado as FotoNoLeida).problema,
        ProblemaLectura.pruebasAgotadas,
      );
      expect(await AccesoLocal(base, () => ahora).fotosDePrueba(), 0);
    });

    test('Con los topes de conexión, pide guardar el avance', () async {
      responder = () =>
          http.Response('{"error":"pruebas_no_disponibles"}', 429);
      final resultado = await lector().leer('/foto.jpg');
      expect((resultado as FotoNoLeida).problema, ProblemaLectura.sinCuenta);
      expect(await AccesoLocal(base, () => ahora).fotosDePrueba(), 3);
    });

    test('El QR de la foto no gasta pruebas', () async {
      qr.contenido = '20100070970|01|F001|00000245|14.95|98.00|2026-10-13|6|1|';
      await lector().leer('/foto.jpg');
      expect(pedidos, isEmpty);
      expect(await AccesoLocal(base, () => ahora).fotosDePrueba(), 3);
    });
  });

  test('Con cuenta no hay fotos de prueba', () async {
    expect(await AccesoLocal(base, () => ahora).fotosDePrueba(), isNull);
  });

  test('En la Demo se usan los comprobantes de ejemplo', () async {
    await AccesoLocal(base, () => ahora).guardarAjuste('modo', 'demo');
    await lector().leer('/foto.jpg');
    expect(deEjemplo.usado, isTrue);
    expect(pedidos, isEmpty);
  });
}
