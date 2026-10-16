import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:http/http.dart' as http;

import '../../dominio/comprobantes.dart';
import '../../dominio/cuenta_real.dart';
import '../../dominio/modelos.dart';
import '../../pais/peru/qr_sunat.dart';
import '../local/base_local.dart';
import '../repositorios/acceso_local.dart';
import 'servicio_cuenta_remoto.dart';

/// La lectura de fotos de verdad (docs/v1-real.md, entrega 14): primero el
/// código QR dentro de la foto, en el teléfono y gratis; si no hay, la IA
/// del servidor. En la Demo, los comprobantes de ejemplo.
class LectorFotoRemoto implements LectorFoto {
  LectorFotoRemoto(
    BaseLocal base, {
    required this._llavero,
    required this._buscadorQr,
    required this._deEjemplo,
    http.Client? cliente,
    DateTime Function()? ahora,
    Future<bool> Function()? hayConexion,
    Future<List<int>> Function(String ruta)? leerArchivo,
    String servidor = direccionServidor,
  }) : _a = AccesoLocal(base, ahora ?? DateTime.now),
       _cliente = cliente ?? http.Client(),
       _hayConexion = hayConexion ?? (() async => true),
       _leerArchivo = leerArchivo ?? ((ruta) => File(ruta).readAsBytes()),
       _servidor = Uri.parse(servidor);

  final AccesoLocal _a;
  final Llavero _llavero;
  final BuscadorQr _buscadorQr;

  /// El de la Demo, que también atiende la foto ilegible forzada por el
  /// operador.
  final LectorFoto _deEjemplo;
  final http.Client _cliente;
  final Future<bool> Function() _hayConexion;
  final Future<List<int>> Function(String ruta) _leerArchivo;
  final Uri _servidor;

  /// Si hace falta el modelo mayor, la lectura tarda más.
  static const _espera = Duration(seconds: 90);

  @override
  Future<ResultadoLectura> leer(String rutaImagen) async {
    if (await _a.enDemo()) return _deEjemplo.leer(rutaImagen);

    // El QR del comprobante electrónico dice lo mismo, exacto y sin costo.
    final String? contenido;
    try {
      contenido = await _buscadorQr.buscar(rutaImagen);
    } on Object {
      return _conIa(rutaImagen);
    }
    if (contenido != null) {
      if (leerQrSunat(contenido) case final qr?) {
        return FotoLeida(
          LecturaComprobante(
            origen: OrigenLectura.qr,
            emisorIdentificacion: qr.emisorIdentificacion,
            tipo: qr.tipo,
            serie: qr.serie,
            numero: qr.numero,
            fechaEmision: qr.fechaEmision,
            impuestoCentimos: qr.impuestoCentimos,
            totalCentimos: qr.totalCentimos,
            rutaImagen: rutaImagen,
          ),
        );
      }
    }
    return _conIa(rutaImagen);
  }

  Future<ResultadoLectura> _conIa(String rutaImagen) async {
    // Sin cuenta, unas pocas fotos de prueba (entrega 14.2).
    final conCuenta =
        await _a.leerAjuste(AccesoLocal.claveCuentaVerificada) != null;
    final llave = conCuenta ? await _llavero.leer() : null;
    if (conCuenta && llave == null) {
      return const FotoNoLeida(ProblemaLectura.sinCuenta);
    }
    final quedan = await _a.fotosDePrueba();
    if (!conCuenta && quedan == 0) {
      return const FotoNoLeida(ProblemaLectura.pruebasAgotadas);
    }
    if (!await _hayConexion()) {
      return const FotoNoLeida(ProblemaLectura.sinSenal);
    }

    final http.Response respuesta;
    try {
      final cuerpo = {
        'imagen': base64Encode(await _leerArchivo(rutaImagen)),
        'tipo': 'image/jpeg',
        'categorias': await _categoriasDeGasto(),
        if (!conCuenta) 'telefono': (await _a.usuario()).id,
      };
      respuesta = await _cliente
          .post(
            _servidor.resolve(
              conCuenta ? '/comprobantes/leer' : '/comprobantes/leer-prueba',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': ?(llave == null ? null : 'Bearer $llave'),
            },
            body: jsonEncode(cuerpo),
          )
          .timeout(_espera);
    } on TimeoutException {
      return const FotoNoLeida(ProblemaLectura.sinSenal);
    } on http.ClientException {
      return const FotoNoLeida(ProblemaLectura.sinSenal);
    }

    final cuerpo = switch (respuesta.body) {
      '' => const <String, Object?>{},
      final texto => jsonDecode(texto) as Map<String, Object?>,
    };
    if (respuesta.statusCode == 429) {
      return switch (cuerpo['error']) {
        'pruebas_agotadas' => () async {
          await _a.guardarAjuste(AccesoLocal.claveFotosDePrueba, '0');
          return const FotoNoLeida(ProblemaLectura.pruebasAgotadas);
        }(),
        // Los topes por conexión o del día: que guarde su avance.
        'pruebas_no_disponibles' => const FotoNoLeida(
          ProblemaLectura.sinCuenta,
        ),
        _ => const FotoNoLeida(ProblemaLectura.limiteDiario),
      };
    }
    if (respuesta.statusCode != 200) {
      return const FotoNoLeida(ProblemaLectura.sinSenal);
    }

    // De prueba: cuál fue y cuántas quedan, según el servidor.
    int? fotoDePrueba;
    if (!conCuenta) {
      final restantes = cuerpo['pruebasRestantes'] as int? ?? 0;
      await _a.guardarAjuste(AccesoLocal.claveFotosDePrueba, '$restantes');
      fotoDePrueba = AccesoLocal.fotosDePruebaIniciales - restantes;
    }
    final lectura = cuerpo['lectura'] as Map<String, Object?>?;
    return switch (cuerpo['resultado']) {
      'leido' when lectura != null => FotoLeida(
        _lectura(
          lectura,
          rutaImagen,
          legible: true,
          fotoDePrueba: fotoDePrueba,
        ),
      ),
      'ilegible' => FotoLeida(
        _lectura(
          lectura ?? const {},
          rutaImagen,
          legible: false,
          fotoDePrueba: fotoDePrueba,
        ),
      ),
      'no_es_comprobante' => const FotoNoLeida(ProblemaLectura.noEsComprobante),
      _ => const FotoNoLeida(ProblemaLectura.sinSenal),
    };
  }

  static LecturaComprobante _lectura(
    Map<String, Object?> l,
    String rutaImagen, {
    required bool legible,
    int? fotoDePrueba,
  }) => LecturaComprobante(
    origen: OrigenLectura.foto,
    legible: legible,
    emisorIdentificacion: l['emisor_identificacion'] as String?,
    emisorNombre: l['emisor_nombre'] as String?,
    tipo: l['tipo'] as String?,
    serie: l['serie'] as String?,
    numero: l['numero'] as String?,
    fechaEmision: _dia(l['fecha_emision'] as String?),
    impuestoCentimos: l['impuesto_centimos'] as int?,
    totalCentimos: l['total_centimos'] as int?,
    cantidadItems: l['cantidad_items'] as int?,
    categoria: l['categoria'] as String?,
    rutaImagen: rutaImagen,
    fotoDePrueba: fotoDePrueba,
  );

  /// «2026-10-13» como medianoche del teléfono.
  static DateTime? _dia(String? texto) {
    if (texto == null) return null;
    final [anio, mes, dia] = texto.split('-').map(int.parse).toList();
    return DateTime(anio, mes, dia);
  }

  /// Para que la IA sugiera una de las categorías del negocio.
  Future<List<String>> _categoriasDeGasto() async {
    final base = _a.base;
    final filas =
        await (base.select(base.categorias)..where(
              (c) =>
                  c.tipoMovimiento.equalsValue(TipoMovimiento.egreso) &
                  c.activa.equals(true),
            ))
            .get();
    return [for (final c in filas) c.nombre];
  }
}
