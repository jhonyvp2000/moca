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
    if (await _a.leerAjuste(AccesoLocal.claveCuentaVerificada) == null) {
      return const FotoNoLeida(ProblemaLectura.sinCuenta);
    }
    final llave = await _llavero.leer();
    if (llave == null) return const FotoNoLeida(ProblemaLectura.sinCuenta);
    if (!await _hayConexion()) {
      return const FotoNoLeida(ProblemaLectura.sinSenal);
    }

    final http.Response respuesta;
    try {
      final imagen = base64Encode(await _leerArchivo(rutaImagen));
      respuesta = await _cliente
          .post(
            _servidor.resolve('/comprobantes/leer'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $llave',
            },
            body: jsonEncode({
              'imagen': imagen,
              'tipo': 'image/jpeg',
              'categorias': await _categoriasDeGasto(),
            }),
          )
          .timeout(_espera);
    } on TimeoutException {
      return const FotoNoLeida(ProblemaLectura.sinSenal);
    } on http.ClientException {
      return const FotoNoLeida(ProblemaLectura.sinSenal);
    }

    if (respuesta.statusCode == 429) {
      return const FotoNoLeida(ProblemaLectura.limiteDiario);
    }
    if (respuesta.statusCode != 200) {
      return const FotoNoLeida(ProblemaLectura.sinSenal);
    }
    final cuerpo = jsonDecode(respuesta.body) as Map<String, Object?>;
    final lectura = cuerpo['lectura'] as Map<String, Object?>?;
    return switch (cuerpo['resultado']) {
      'leido' when lectura != null => FotoLeida(
        _lectura(lectura, rutaImagen, legible: true),
      ),
      'ilegible' => FotoLeida(
        _lectura(lectura ?? const {}, rutaImagen, legible: false),
      ),
      'no_es_comprobante' => const FotoNoLeida(ProblemaLectura.noEsComprobante),
      _ => const FotoNoLeida(ProblemaLectura.sinSenal),
    };
  }

  static LecturaComprobante _lectura(
    Map<String, Object?> l,
    String rutaImagen, {
    required bool legible,
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
