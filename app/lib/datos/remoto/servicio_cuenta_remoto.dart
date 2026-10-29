import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../dominio/cuenta_real.dart';
import '../../dominio/medicion.dart';
import '../../dominio/modelos.dart';
import '../local/base_local.dart';
import '../local/categorias_al_dia.dart';
import '../repositorios/acceso_local.dart';
import '../repositorios/repositorio_tutoria_local.dart';

/// La dirección del servidor. Se cambia al compilar con
/// `--dart-define=MOCA_SERVIDOR=…`.
const direccionServidor = String.fromEnvironment(
  'MOCA_SERVIDOR',
  defaultValue: 'https://moca-servidor.onrender.com',
);

/// La cuenta real contra el servidor de Moca (servidor/README.md).
class ServicioCuentaRemoto implements ServicioCuenta {
  ServicioCuentaRemoto(
    BaseLocal base, {
    required this._llavero,
    this._lectorSms = const SinLectorSms(),
    http.Client? cliente,
    DateTime Function()? ahora,
    Future<bool> Function()? hayConexion,
    String servidor = direccionServidor,
  }) : _base = base,
       _a = AccesoLocal(base, ahora ?? DateTime.now),
       _cliente = cliente ?? http.Client(),
       _hayConexion = hayConexion ?? (() async => true),
       _servidor = Uri.parse(servidor);

  final BaseLocal _base;
  final AccesoLocal _a;
  final Llavero _llavero;
  final LectorCodigoSms _lectorSms;
  final http.Client _cliente;
  final Future<bool> Function() _hayConexion;
  final Uri _servidor;

  /// El servidor gratuito de Render se duerme y tarda en despertar.
  static const _espera = Duration(seconds: 75);

  /// Lo que subió la última vez, para no repetir subidas sin cambios.
  static const _claveHuellaSubida = 'subida_huella';
  static const _claveSinCuentaDesde = 'sin_cuenta_desde';

  /// La cuenta se abrió en otro teléfono y el servidor ya no acepta la
  /// llave de este.
  static const _claveCerrada = 'cuenta_cerrada_en_otro';

  /// Un dueño quitó a esta persona del negocio (entrega 18).
  static const _claveFuera = 'fuera_del_negocio';

  /// Desde qué número de cambio pedir lo nuevo, cuándo se pidió por última
  /// vez y cuántas personas hay en el negocio (entrega 18).
  static const _claveDesde = 'cambios_desde';
  static const _claveActualizado = 'actualizado_en';
  static const _clavePersonas = 'personas_en_el_negocio';

  /// Para que un aviso marcado «Entendido» suba siempre con el mismo id.
  static const _uuid = Uuid();

  /// A los cuántos días de «Ahora no» aparece la tarjeta de Moca.
  static const diasParaRecordar = 3;

  /// Con [comprimir], el cuerpo va en gzip: lo que se anota en un año pesa
  /// menos que una foto (entrega 12).
  Future<http.Response> _enviar(
    String ruta,
    Object cuerpo, {
    String? llave,
    bool comprimir = false,
  }) {
    final bytes = utf8.encode(jsonEncode(cuerpo));
    return _cliente
        .post(
          _servidor.resolve(ruta),
          headers: {
            'Content-Type': 'application/json',
            'Content-Encoding': ?(comprimir ? 'gzip' : null),
            'Authorization': ?(llave == null ? null : 'Bearer $llave'),
          },
          body: comprimir ? gzip.encode(bytes) : bytes,
        )
        .timeout(_espera);
  }

  Future<http.Response> _pedir(String ruta, String llave) => _cliente
      .get(_servidor.resolve(ruta), headers: {'Authorization': 'Bearer $llave'})
      .timeout(_espera);

  /// Guarda las cifras que vinieron en la respuesta, si vinieron.
  Future<void> _guardarCifras(
    Map<String, Object?> cuerpo,
    String huella,
  ) async {
    if (cuerpo['cifras'] case final Map<String, Object?> cifras) {
      await _a.guardarCifras(cifras, huella);
    }
  }

  static Map<String, Object?> _cuerpo(http.Response r) {
    try {
      return jsonDecode(r.body) as Map<String, Object?>;
    } on FormatException {
      return const {};
    }
  }

  @override
  Future<ResultadoPedido> pedirCodigo(String celular) async {
    if (!await _hayConexion()) return ResultadoPedido.sinSenal;
    // Se escucha antes de pedirlo: el SMS puede llegar en segundos. Con la
    // marca al final, Android se lo da a Moca (entrega 14.7).
    String? marca;
    try {
      marca = await _lectorSms.marca();
      if (marca != null) await _lectorSms.esperar();
    } on Object {
      marca = null;
    }
    try {
      final respuesta = await _enviar('/cuenta/codigo', {
        'celular': celular,
        'marcaApp': ?marca,
      });
      return switch (respuesta.statusCode) {
        200 => ResultadoPedido.enviado,
        429 => ResultadoPedido.demasiados,
        400 => ResultadoPedido.invalido,
        _ => ResultadoPedido.error,
      };
    } on TimeoutException {
      return ResultadoPedido.sinSenal;
    } on http.ClientException {
      return ResultadoPedido.sinSenal;
    }
  }

  @override
  Future<ResultadoVerificacion> verificar(
    String celular,
    String codigo, {
    bool entrar = false,
  }) async {
    if (!await _hayConexion()) return ResultadoVerificacion.sinSenal;
    final http.Response respuesta;
    try {
      respuesta = await _enviar('/cuenta/verificar', {
        'celular': celular,
        'codigo': codigo,
        if (entrar)
          'modo': 'entrar'
        else ...{
          'modo': 'guardar',
          'usuarioId': (await _a.usuario()).id,
        },
      });
    } on TimeoutException {
      return ResultadoVerificacion.sinSenal;
    } on http.ClientException {
      return ResultadoVerificacion.sinSenal;
    }
    final cuerpo = _cuerpo(respuesta);
    switch (respuesta.statusCode) {
      case 200:
        if (cuerpo['cuentaExistente'] == true || cuerpo['llave'] == null) {
          // El dueño elige qué hacer con el pase (entrega 14.4).
          _pase = cuerpo['pase'] as String?;
          _celularPorEntrar = celular;
          return ResultadoVerificacion.otraCuenta;
        }
        await _llavero.guardar(cuerpo['llave']! as String);
        if (entrar) {
          // La cuenta queda verificada cuando termina de bajar.
          _celularPorEntrar = celular;
          return ResultadoVerificacion.verificado;
        }
        await _cuentaGuardada(celular);
        return ResultadoVerificacion.verificado;
      case 400:
        return cuerpo['error'] == 'codigo_vencido'
            ? ResultadoVerificacion.vencido
            : ResultadoVerificacion.incorrecto;
      case 404:
        return ResultadoVerificacion.sinCuenta;
      case 409:
        return ResultadoVerificacion.otraCuenta;
      default:
        return ResultadoVerificacion.error;
    }
  }

  /// El celular con el que se entró, mientras se bajan los datos.
  String? _celularPorEntrar;

  /// Con un número que ya tenía cuenta: el pase para elegir sin otro SMS, y
  /// la llave de esa cuenta si ya se canjeó (entrega 14.4).
  String? _pase;
  String? _llaveDeLaCuenta;

  /// El número quedó verificado en este teléfono: lo anotado antes de la
  /// cuenta queda por subir.
  Future<void> _cuentaGuardada(String celular) async {
    await _a.guardarAjuste(AccesoLocal.claveCuentaVerificada, celular);
    await _base
        .update(_base.movimientos)
        .write(
          const MovimientosCompanion(
            estadoSincronizacion: Value(EstadoSincronizacion.porSubir),
          ),
        );
  }

  /// Canjea el pase: «entrar» o «empezar_de_cero». Devuelve la llave, o por
  /// qué no.
  Future<(String?, ResultadoBajada?)> _canjearPase(
    String accion, {
    String? usuarioId,
  }) async {
    final pase = _pase;
    if (pase == null) return (null, ResultadoBajada.vencido);
    if (!await _hayConexion()) return (null, ResultadoBajada.sinSenal);
    final http.Response respuesta;
    try {
      respuesta = await _enviar('/cuenta/con-pase', {
        'pase': pase,
        'accion': accion,
        'usuarioId': ?usuarioId,
      });
    } on TimeoutException {
      return (null, ResultadoBajada.sinSenal);
    } on http.ClientException {
      return (null, ResultadoBajada.sinSenal);
    }
    if (respuesta.statusCode == 410) {
      _pase = null;
      return (null, ResultadoBajada.vencido);
    }
    final llave = _cuerpo(respuesta)['llave'];
    if (respuesta.statusCode != 200 || llave is! String) {
      return (null, ResultadoBajada.error);
    }
    _pase = null;
    return (llave, null);
  }

  @override
  Future<ResultadoBajada> entrarYSumar() async {
    final celular = _celularPorEntrar;
    if (celular == null) return ResultadoBajada.error;
    var llave = _llaveDeLaCuenta;
    if (llave == null) {
      final (nueva, problema) = await _canjearPase('entrar');
      if (nueva == null) return problema!;
      llave = _llaveDeLaCuenta = nueva;
    }
    if (!await _hayConexion()) return ResultadoBajada.sinSenal;
    // Lo de este teléfono, antes de que lo reemplace lo de la cuenta.
    final empresa = await _a.empresa();
    final local = empresa == null
        ? const <String, Object?>{}
        : await _datosParaSubir(empresa);
    final http.Response respuesta;
    try {
      respuesta = await _pedir('/datos/bajar', llave);
    } on TimeoutException {
      return ResultadoBajada.sinSenal;
    } on http.ClientException {
      return ResultadoBajada.sinSenal;
    }
    if (respuesta.statusCode != 200) return ResultadoBajada.error;
    final cuerpo = _cuerpo(respuesta);
    final datos = cuerpo['datos'];
    if (datos is! Map<String, Object?>) return ResultadoBajada.error;
    await _guardarBajada(datos, celular, sumar: local);
    await _llavero.guardar(llave);
    _celularPorEntrar = null;
    _llaveDeLaCuenta = null;
    return ResultadoBajada.listo;
  }

  @override
  Future<ResultadoVerificacion> empezarDeCero() async {
    final celular = _celularPorEntrar;
    if (celular == null) return ResultadoVerificacion.error;
    final (llave, problema) = await _canjearPase(
      'empezar_de_cero',
      usuarioId: (await _a.usuario()).id,
    );
    if (llave == null) {
      return switch (problema) {
        ResultadoBajada.sinSenal => ResultadoVerificacion.sinSenal,
        ResultadoBajada.vencido => ResultadoVerificacion.vencido,
        _ => ResultadoVerificacion.error,
      };
    }
    await _llavero.guardar(llave);
    await _cuentaGuardada(celular);
    _celularPorEntrar = null;
    return ResultadoVerificacion.verificado;
  }

  @override
  Future<ResultadoBorrado> borrarEnElServidor() async {
    final llave = await _llavero.leer();
    if (llave == null ||
        await _a.leerAjuste(AccesoLocal.claveCuentaVerificada) == null) {
      return ResultadoBorrado.sinCuenta;
    }
    if (!await _hayConexion()) return ResultadoBorrado.sinSenal;
    // Una subida a medias podría volver a crear lo borrado: se espera a que
    // termine y no empieza otra mientras tanto.
    for (var i = 0; _subiendo && i < 150; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (_subiendo) return ResultadoBorrado.error;
    _subiendo = true;
    try {
      final respuesta = await _enviar('/cuenta/borrar-datos', {
        'confirmacion': 'BORRAR',
      }, llave: llave);
      return respuesta.statusCode == 200
          ? ResultadoBorrado.listo
          : ResultadoBorrado.error;
    } on TimeoutException {
      return ResultadoBorrado.sinSenal;
    } on http.ClientException {
      return ResultadoBorrado.sinSenal;
    } finally {
      _subiendo = false;
    }
  }

  @override
  Future<ResultadoBajada> bajarTodo() async {
    final llave = await _llavero.leer();
    final celular = _celularPorEntrar;
    if (llave == null || celular == null) return ResultadoBajada.error;
    if (!await _hayConexion()) return ResultadoBajada.sinSenal;
    final http.Response respuesta;
    try {
      respuesta = await _pedir('/datos/bajar', llave);
    } on TimeoutException {
      return ResultadoBajada.sinSenal;
    } on http.ClientException {
      return ResultadoBajada.sinSenal;
    }
    if (respuesta.statusCode != 200) return ResultadoBajada.error;
    final cuerpo = _cuerpo(respuesta);
    final datos = cuerpo['datos'];
    if (datos is! Map<String, Object?>) return ResultadoBajada.error;
    await _guardarBajada(datos, celular);
    await _guardarCifras(cuerpo, await _a.huella());
    _celularPorEntrar = null;
    return ResultadoBajada.listo;
  }

  @override
  Stream<SituacionCuenta> observar() =>
      _a.cambios().asyncMap((_) => _situacion());

  Future<SituacionCuenta> _situacion() async {
    final verificado = await _a.leerAjuste(AccesoLocal.claveCuentaVerificada);
    if (verificado != null) {
      if (await _a.leerAjuste(_claveCerrada) != null) {
        return SituacionCuenta(
          estado: EstadoCuenta.cerradaEnOtro,
          celular: verificado,
          mostrarTarjeta: true,
        );
      }
      if (await _a.leerAjuste(_claveFuera) != null) {
        return SituacionCuenta(
          estado: EstadoCuenta.fueraDelNegocio,
          celular: verificado,
          mostrarTarjeta: true,
        );
      }
      return SituacionCuenta(
        estado: EstadoCuenta.guardada,
        celular: verificado,
        actualizadoEn: DateTime.tryParse(
          await _a.leerAjuste(_claveActualizado) ?? '',
        ),
        variasPersonas:
            (int.tryParse(await _a.leerAjuste(_clavePersonas) ?? '') ?? 1) > 1,
      );
    }
    final celular = (await _a.usuarioONulo())?.celular;
    final enDemo = await _a.enDemo();
    final etapaLista = await _a.leerAjuste('etapa') == 'listo';
    if (celular != null) {
      return SituacionCuenta(
        estado: EstadoCuenta.porConfirmar,
        celular: celular,
        mostrarTarjeta: !enDemo && etapaLista,
      );
    }
    final desde = DateTime.tryParse(
      await _a.leerAjuste(_claveSinCuentaDesde) ?? '',
    );
    return SituacionCuenta(
      estado: EstadoCuenta.sinCuenta,
      mostrarTarjeta:
          !enDemo &&
          etapaLista &&
          desde != null &&
          !_a.ahora().isBefore(
            desde.add(const Duration(days: diasParaRecordar)),
          ),
    );
  }

  bool _subiendo = false;

  @override
  Future<bool> subirTodo() async {
    if (_subiendo) return false;
    if (await _a.leerAjuste(AccesoLocal.claveCuentaVerificada) == null) {
      return false;
    }
    if (await _a.enDemo() || !await _hayConexion()) return false;
    if (await _bloqueada()) return false;
    final llave = await _llavero.leer();
    if (llave == null) return false;
    _subiendo = true;
    try {
      final empresa = await _a.empresa();
      if (empresa == null) return false;
      // Solo lo que el servidor no tiene igual (entrega 18).
      final datos = await _soloLoQueCambio(await _datosParaSubir(empresa));
      final huella = await _a.huella();
      final respuesta = await _enviar(
        '/datos/subir',
        datos,
        llave: llave,
        comprimir: true,
      );
      if (respuesta.statusCode == 401) {
        // La cuenta se abrió en otro teléfono.
        await _a.guardarAjuste(_claveCerrada, _a.ahora().toIso8601String());
        return false;
      }
      final cuerpo = _cuerpo(respuesta);
      if (respuesta.statusCode == 403 &&
          cuerpo['error'] == 'no_es_tu_empresa') {
        await _a.guardarAjuste(_claveFuera, _a.ahora().toIso8601String());
        return false;
      }
      if (respuesta.statusCode != 200) return false;
      // Solo lo que existía al armar la subida queda marcado como subido.
      final subidos = [
        for (final m in datos['movimientos']! as List)
          (m as Map)['id'] as String,
      ];
      await _base.transaction(() async {
        await (_base.update(
          _base.movimientos,
        )..where((m) => m.id.isIn(subidos))).write(
          const MovimientosCompanion(
            estadoSincronizacion: Value(EstadoSincronizacion.subido),
          ),
        );
        await _recordarEnServidor(datos);
        await _a.guardarAjuste(_claveHuellaSubida, huella);
        // Las cifras con lo subido (entrega 13): valen mientras no cambie
        // nada en el teléfono.
        await _guardarCifras(cuerpo, huella);
      });
      return true;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } finally {
      _subiendo = false;
    }
  }

  /// Si hubo cambios desde la última subida: algo «por subir» o una huella
  /// distinta. La bitácora registra cada cambio; los días cerrados y la
  /// empresa se suman aparte.
  @override
  Future<bool> hayCambiosSinSubir() async =>
      await _a.hayPorSubir() ||
      await _a.huella() != await _a.leerAjuste(_claveHuellaSubida);

  bool _pidiendoCifras = false;

  @override
  Future<void> actualizarCifras() async {
    if (_pidiendoCifras || _subiendo) return;
    if (await _a.leerAjuste(AccesoLocal.claveCuentaVerificada) == null) return;
    if (await _a.enDemo() || await _bloqueada()) return;
    if (await hayCambiosSinSubir()) return;
    if (await _a.cifrasDelServidor() != null) return;
    if (!await _hayConexion()) return;
    final llave = await _llavero.leer();
    if (llave == null) return;
    _pidiendoCifras = true;
    try {
      final huella = await _a.huella();
      final respuesta = await _pedir('/cifras', llave);
      if (respuesta.statusCode == 401) {
        await _a.guardarAjuste(_claveCerrada, _a.ahora().toIso8601String());
        return;
      }
      if (respuesta.statusCode != 200) return;
      await _guardarCifras(_cuerpo(respuesta), huella);
    } on TimeoutException {
      return;
    } on http.ClientException {
      return;
    } finally {
      _pidiendoCifras = false;
    }
  }

  /// La cuenta ya no sube ni baja: se abrió en otro teléfono o lo quitaron
  /// del negocio.
  Future<bool> _bloqueada() async =>
      await _a.leerAjuste(_claveCerrada) != null ||
      await _a.leerAjuste(_claveFuera) != null;

  bool _trayendo = false;

  @override
  Future<bool> traerCambios() async {
    if (_trayendo || _subiendo) return false;
    if (await _a.leerAjuste(AccesoLocal.claveCuentaVerificada) == null) {
      return false;
    }
    if (await _a.enDemo() || await _bloqueada()) return false;
    if (!await _hayConexion()) return false;
    final llave = await _llavero.leer();
    final empresa = await _a.empresa();
    if (llave == null || empresa == null) return false;
    _trayendo = true;
    try {
      final desde = int.tryParse(await _a.leerAjuste(_claveDesde) ?? '') ?? 0;
      final respuesta = await _pedir('/datos/cambios?desde=$desde', llave);
      if (respuesta.statusCode == 401) {
        await _a.guardarAjuste(_claveCerrada, _a.ahora().toIso8601String());
        return false;
      }
      final cuerpo = _cuerpo(respuesta);
      if (respuesta.statusCode == 403 && cuerpo['error'] == 'sin_negocio') {
        await _a.guardarAjuste(_claveFuera, _a.ahora().toIso8601String());
        return false;
      }
      if (respuesta.statusCode != 200 || cuerpo['empresa_id'] != empresa.id) {
        return false;
      }
      final hayAlgo = cuerpo.entries.any(
        (e) => e.value is List && (e.value! as List).isNotEmpty,
      );
      final sinPendientes = !await hayCambiosSinSubir();
      await _base.transaction(() async {
        if (hayAlgo || cuerpo['empresa'] != null) {
          // Lo anotado aquí que todavía no subió no se pisa: sube después.
          final pendientes = {
            for (final m
                in await (_base.select(_base.movimientos)..where(
                      (m) => m.estadoSincronizacion.equalsValue(
                        EstadoSincronizacion.porSubir,
                      ),
                    ))
                    .get())
              m.id,
          };
          final datos = {
            ...cuerpo,
            'movimientos': [
              for (final m in (cuerpo['movimientos'] as List? ?? const []))
                if (!pendientes.contains((m as Map)['id'])) m,
            ],
          };
          await _asegurarAutores(datos);
          await _base.batch(
            (lote) => _insertarFilas(lote, datos, empresa.id, actualizar: true),
          );
          if (cuerpo['empresa'] case final Map<String, Object?> e) {
            await (_base.update(
              _base.empresas,
            )..where((x) => x.id.equals(empresa.id))).write(
              EmpresasCompanion(
                nombre: Value(e['nombre']! as String),
                tipoNegocio: Value(
                  _enum(TipoNegocio.values, e['tipo_negocio']),
                ),
                horaCierreMinutos: Value(e['hora_cierre_minutos']! as int),
                identificacionFiscal: Value(
                  e['identificacion_fiscal'] as String?,
                ),
              ),
            );
          }
          await _recordarVideosVistos(datos);
          // Lo que bajó ya está así en el servidor.
          final actual = await _a.empresa();
          await _recordarEnServidor(
            await _datosParaSubir(actual!),
            soloIds: _idsDe(datos),
          );
        }
        if (cuerpo['hasta'] case final int hasta) {
          await _a.guardarAjuste(_claveDesde, '$hasta');
        }
        if (cuerpo['personas'] case final int personas) {
          await _a.guardarAjuste(_clavePersonas, '$personas');
        }
        await _a.guardarAjuste(_claveActualizado, _a.ahora().toIso8601String());
        // Sin nada propio por subir, el teléfono sigue al día con el
        // servidor.
        if (sinPendientes) {
          await _a.guardarAjuste(_claveHuellaSubida, await _a.huella());
        }
      });
      return hayAlgo;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } finally {
      _trayendo = false;
    }
  }

  /// Quienes anotaron lo que bajó: en el teléfono cada registro apunta a su
  /// autor, así que las otras personas del negocio también se guardan aquí,
  /// sin celular (entrega 18).
  Future<void> _asegurarAutores(Map<String, Object?> datos) async {
    final autores = {
      for (final tabla in ['movimientos', 'arqueos', 'bitacora'])
        for (final f in (datos[tabla] as List? ?? const []))
          if (f case {'autor_id': final String autor}) autor,
    };
    if (autores.isEmpty) return;
    await _base.batch(
      (lote) => lote.insertAll(_base.usuarios, [
        for (final id in autores)
          UsuariosCompanion.insert(id: id, creadoEn: _a.ahora()),
      ], mode: InsertMode.insertOrIgnore),
    );
  }

  /// La huella de una fila tal como se sube.
  static String _huellaFila(Object? fila) =>
      sha1.convert(utf8.encode(jsonEncode(fila))).toString();

  /// «tabla/id» de cada fila de [datos], con la empresa.
  static Set<String> _idsDe(Map<String, Object?> datos) => {
    if (datos['empresa'] case {'id': final Object id}) 'empresa/$id',
    for (final MapEntry(key: tabla, value: filas) in datos.entries)
      if (filas is List)
        for (final f in filas)
          if (f case {'id': final Object id}) '$tabla/$id',
  };

  /// De todo lo del teléfono, solo lo que el servidor no tiene igual. La
  /// empresa va siempre: el servidor la necesita para saber de quién es.
  Future<Map<String, Object>> _soloLoQueCambio(
    Map<String, Object> datos,
  ) async {
    final conocidas = {
      for (final s in await _base.select(_base.subidas).get())
        '${s.tabla}/${s.filaId}': s.huella,
    };
    return {
      for (final MapEntry(key: tabla, value: filas) in datos.entries)
        tabla: filas is List
            ? [
                for (final f in filas)
                  if (conocidas['$tabla/${(f as Map)['id']}'] != _huellaFila(f))
                    f,
              ]
            : filas,
    };
  }

  /// Anota que estas filas ya están así en el servidor; con [soloIds], solo
  /// esas («tabla/id»).
  Future<void> _recordarEnServidor(
    Map<String, Object?> datos, {
    Set<String>? soloIds,
  }) async {
    final filas = <SubidasCompanion>[];
    void anotar(String tabla, Object? fila) {
      if (fila case {'id': final String id}) {
        if (soloIds != null && !soloIds.contains('$tabla/$id')) return;
        filas.add(
          SubidasCompanion.insert(
            tabla: tabla,
            filaId: id,
            huella: _huellaFila(fila),
          ),
        );
      }
    }

    for (final MapEntry(key: tabla, value: valor) in datos.entries) {
      if (valor is List) {
        for (final f in valor) {
          anotar(tabla, f);
        }
      } else {
        anotar(tabla, valor);
      }
    }
    await _base.batch(
      (lote) => lote.insertAllOnConflictUpdate(_base.subidas, filas),
    );
  }

  // --- Lo que se baja ------------------------------------------------------

  static DateTime _desdeFecha(Object? v) =>
      DateTime.parse(v! as String).toLocal();

  static DateTime? _desdeFechaONulo(Object? v) =>
      v == null ? null : _desdeFecha(v);

  /// «2026-10-11» como medianoche del teléfono.
  static DateTime? _desdeDia(Object? v) {
    if (v == null) return null;
    final [anio, mes, dia] = (v as String).split('-').map(int.parse).toList();
    return DateTime(anio, mes, dia);
  }

  static String? _aTexto(Object? json) =>
      json == null ? null : jsonEncode(json);

  static T _enum<T extends Enum>(List<T> valores, Object? nombre) =>
      valores.byName(nombre! as String);

  /// Reemplaza lo del teléfono por lo que bajó de la cuenta, en una sola
  /// transacción: si algo falla, el teléfono queda como estaba.
  Future<void> _guardarBajada(
    Map<String, Object?> datos,
    String celular, {
    Map<String, Object?>? sumar,
  }) async {
    final usuario = datos['usuario']! as Map<String, Object?>;
    final membresia = datos['membresia']! as Map<String, Object?>;
    final empresa = datos['empresa']! as Map<String, Object?>;
    final usuarioId = usuario['id']! as String;
    final empresaId = empresa['id']! as String;

    await _base.transaction(() async {
      // El teléfono viene de la Bienvenida: no hay datos propios que perder.
      for (final TableInfo tabla in [
        _base.bitacora,
        _base.arqueoCuentas,
        _base.arqueos,
        _base.movimientos,
        _base.itemsComprobante,
        _base.comprobantes,
        _base.contrapartes,
        _base.categorias,
        _base.cuentas,
        _base.diasCerrados,
        _base.alertas,
        _base.membresias,
        _base.empresas,
        _base.usuarios,
        _base.subidas,
      ]) {
        await _base.delete(tabla).go();
      }

      await _base
          .into(_base.usuarios)
          .insert(
            UsuariosCompanion.insert(
              id: usuarioId,
              celular: Value(celular),
              creadoEn: _a.ahora(),
            ),
          );
      await _base
          .into(_base.empresas)
          .insert(
            EmpresasCompanion.insert(
              id: empresaId,
              nombre: empresa['nombre']! as String,
              tipoNegocio: _enum(TipoNegocio.values, empresa['tipo_negocio']),
              modo: _enum(ModoEmpresa.values, empresa['modo']),
              pais: empresa['pais']! as String,
              moneda: empresa['moneda']! as String,
              regimen: Value(empresa['regimen'] as String?),
              horaCierreMinutos: empresa['hora_cierre_minutos']! as int,
              identificacionFiscal: Value(
                empresa['identificacion_fiscal'] as String?,
              ),
              creadoEn: _desdeFecha(empresa['creado_en']),
            ),
          );
      await _base
          .into(_base.membresias)
          .insert(
            MembresiasCompanion.insert(
              id: membresia['id']! as String,
              usuarioId: usuarioId,
              empresaId: empresaId,
              rol: _enum(Rol.values, membresia['rol']),
            ),
          );
      await _asegurarAutores(datos);
      await _base.batch((lote) => _insertarFilas(lote, datos, empresaId));
      await _recordarVideosVistos(datos);
      // Lo que acaba de bajar ya está en el servidor, fila por fila, y lo
      // nuevo se pide desde aquí (entrega 18).
      await _recordarEnServidor(
        await _datosParaSubir((await _a.empresa())!),
        soloIds: _idsDe({...datos, 'empresa': empresa}),
      );
      if (datos['hasta'] case final int hasta) {
        await _a.guardarAjuste(_claveDesde, '$hasta');
      }
      await _a.guardarAjuste(_claveHuellaSubida, await _a.huella());
      // Lo anotado en este teléfono se suma a la cuenta y queda por subir
      // (entrega 14.4).
      if (sumar != null) {
        await _base.batch(
          (lote) => _insertarFilas(
            lote,
            _paraSumar(sumar, datos),
            empresaId,
            estado: EstadoSincronizacion.porSubir,
          ),
        );
      }

      // Si la cuenta trae categorías con nombres viejos, se ponen al día y
      // quedan por subir (entrega 14.14).
      await ponerAlDiaCategorias(_base, _a.nuevoId);

      // Una cuenta que se guardó antes del alta sigue en el alta.
      final conAlta = (empresa['nombre']! as String).isNotEmpty;
      await _a.guardarAjuste('etapa', conAlta ? 'listo' : 'alta');
      await _a.guardarAjuste(AccesoLocal.claveCuentaVerificada, celular);
      for (final clave in [_claveSinCuentaDesde, _claveCerrada, _claveFuera]) {
        await (_base.delete(
          _base.ajustes,
        )..where((a) => a.clave.equals(clave))).go();
      }
    });
  }

  /// Los videos de ayuda que se abrieron con esta cuenta vuelven a la
  /// medición y a «Aprende en 3 minutos» con su ✓ (entrega 14.6).
  Future<void> _recordarVideosVistos(Map<String, Object?> datos) async {
    final filas = [
      for (final f in (datos['videos_vistos'] as List? ?? const []))
        f as Map<String, Object?>,
    ];
    if (filas.isEmpty) return;
    await _base.batch(
      (lote) => lote.insertAll(_base.eventosMedicion, [
        for (final f in filas)
          EventosMedicionCompanion.insert(
            id: f['id']! as String,
            nombre: EventoMedicion.videoAbierto.name,
            fecha: _desdeFecha(f['fecha']),
            datos: Value(
              jsonEncode({'video': f['video'], 'desde': f['desde']}),
            ),
          ),
      ], mode: InsertMode.insertOrIgnore),
    );
    final clave = RepositorioTutoriaLocal.claveVistos;
    final vistos = {
      for (final n in (await _a.leerAjuste(clave) ?? '').split(','))
        ?int.tryParse(n),
      for (final f in filas) f['video']! as int,
    }.toList()..sort();
    await _a.guardarAjuste(clave, vistos.join(','));
  }

  /// Escribe las filas de [datos] (con los nombres del servidor) en la base
  /// del teléfono.
  ///
  /// Con [actualizar], lo que ya estaba se reemplaza por lo que bajó (lo
  /// nuevo de los demás, entrega 18).
  void _insertarFilas(
    Batch lote,
    Map<String, Object?> datos,
    String empresaId, {
    EstadoSincronizacion estado = EstadoSincronizacion.subido,
    bool actualizar = false,
  }) {
    List<Map<String, Object?>> filas(String tabla) => [
      for (final f in (datos[tabla] as List? ?? const []))
        f as Map<String, Object?>,
    ];
    void poner<T extends Table, D>(
      TableInfo<T, D> tabla,
      Iterable<Insertable<D>> nuevas,
    ) => actualizar
        ? lote.insertAllOnConflictUpdate(tabla, nuevas)
        : lote.insertAll(tabla, nuevas);
    poner(_base.cuentas, [
      for (final c in filas('cuentas'))
        CuentasCompanion.insert(
          id: c['id']! as String,
          empresaId: empresaId,
          tipo: _enum(TipoCuenta.values, c['tipo']),
          nombre: c['nombre']! as String,
          orden: c['orden']! as int,
          saldoInicialCentimos: Value(c['saldo_inicial_centimos'] as int?),
          fechaSaldoInicial: Value(_desdeFechaONulo(c['fecha_saldo_inicial'])),
        ),
    ]);
    poner(_base.categorias, [
      for (final c in filas('categorias'))
        CategoriasCompanion.insert(
          id: c['id']! as String,
          empresaId: empresaId,
          nombre: c['nombre']! as String,
          tipoMovimiento: _enum(TipoMovimiento.values, c['tipo_movimiento']),
          orden: c['orden']! as int,
          activa: Value(c['activa']! as bool),
        ),
    ]);
    poner(_base.contrapartes, [
      for (final c in filas('contrapartes'))
        ContrapartesCompanion.insert(
          id: c['id']! as String,
          empresaId: empresaId,
          nombre: c['nombre']! as String,
          identificacionFiscal: Value(c['identificacion_fiscal'] as String?),
          tipo: _enum(TipoContraparte.values, c['tipo']),
        ),
    ]);
    poner(_base.comprobantes, [
      for (final c in filas('comprobantes'))
        ComprobantesCompanion.insert(
          id: c['id']! as String,
          empresaId: empresaId,
          emisorIdentificacion: Value(c['emisor_identificacion'] as String?),
          emisorNombre: Value(c['emisor_nombre'] as String?),
          tipo: Value(c['tipo'] as String?),
          serie: Value(c['serie'] as String?),
          numero: Value(c['numero'] as String?),
          fechaEmision: Value(_desdeDia(c['fecha_emision'])),
          subtotalCentimos: Value(c['subtotal_centimos'] as int?),
          impuestoCentimos: Value(c['impuesto_centimos'] as int?),
          totalCentimos: c['total_centimos']! as int,
          origenLectura: _enum(OrigenLectura.values, c['origen_lectura']),
          creadoEn: _desdeFecha(c['creado_en']),
        ),
    ]);
    poner(_base.itemsComprobante, [
      for (final i in filas('items_comprobante'))
        ItemsComprobanteCompanion.insert(
          id: i['id']! as String,
          comprobanteId: i['comprobante_id']! as String,
          descripcion: i['descripcion']! as String,
          cantidad: Value((i['cantidad'] as num?)?.toDouble()),
          precioUnitarioCentimos: Value(i['precio_unitario_centimos'] as int?),
          importeCentimos: i['importe_centimos']! as int,
        ),
    ]);
    poner(_base.movimientos, [
      for (final m in filas('movimientos'))
        MovimientosCompanion.insert(
          id: m['id']! as String,
          empresaId: empresaId,
          tipo: _enum(TipoMovimiento.values, m['tipo']),
          cuentaId: m['cuenta_id']! as String,
          montoCentimos: m['monto_centimos']! as int,
          fechaMovimiento: _desdeFecha(m['fecha_movimiento']),
          fechaComprobante: Value(_desdeFechaONulo(m['fecha_comprobante'])),
          estadoPago: _enum(EstadoPago.values, m['estado_pago']),
          montoPagadoCentimos: m['monto_pagado_centimos']! as int,
          fechaVencimiento: Value(_desdeFechaONulo(m['fecha_vencimiento'])),
          fechaPago: Value(_desdeFechaONulo(m['fecha_pago'])),
          categoriaId: Value(m['categoria_id'] as String?),
          contraparteId: Value(m['contraparte_id'] as String?),
          comprobanteId: Value(m['comprobante_id'] as String?),
          nivelConfianza: _enum(NivelConfianza.values, m['nivel_confianza']),
          fuente: _enum(Fuente.values, m['fuente']),
          autorId: m['autor_id']! as String,
          nota: Value(m['nota'] as String?),
          estado: _enum(EstadoRegistro.values, m['estado']),
          reemplazaA: Value(m['reemplaza_a'] as String?),
          estadoSincronizacion: estado,
          creadoEn: _desdeFecha(m['creado_en']),
        ),
    ]);
    poner(_base.arqueos, [
      for (final a in filas('arqueos'))
        ArqueosCompanion.insert(
          id: a['id']! as String,
          empresaId: empresaId,
          fecha: _desdeFecha(a['fecha']),
          autorId: a['autor_id']! as String,
          creadoEn: _desdeFecha(a['creado_en']),
        ),
    ]);
    poner(_base.arqueoCuentas, [
      for (final a in filas('arqueo_cuentas'))
        ArqueoCuentasCompanion.insert(
          id: a['id']! as String,
          arqueoId: a['arqueo_id']! as String,
          cuentaId: a['cuenta_id']! as String,
          saldoCalculadoCentimos: a['saldo_calculado_centimos']! as int,
          saldoRealCentimos: a['saldo_real_centimos']! as int,
          diferenciaCentimos: a['diferencia_centimos']! as int,
          motivo: Value(
            a['motivo'] == null
                ? null
                : _enum(MotivoArqueo.values, a['motivo']),
          ),
          movimientoId: Value(a['movimiento_id'] as String?),
        ),
    ]);
    poner(_base.diasCerrados, [
      for (final d in filas('dias_cerrados'))
        DiasCerradosCompanion.insert(
          id: d['id']! as String,
          empresaId: empresaId,
          dia: _desdeDia(d['dia'])!,
        ),
    ]);
    // Los avisos marcados «Entendido»: en el teléfono, su id es la clave.
    poner(_base.alertas, [
      for (final a in filas('alertas'))
        AlertasCompanion.insert(
          id: a['clave']! as String,
          empresaId: empresaId,
          tipo: a['tipo']! as String,
          prioridad: _enum(PrioridadAlerta.values, a['prioridad']),
          estado: _enum(EstadoAlerta.values, a['estado']),
          texto: a['texto']! as String,
          datos: _aTexto(a['datos']) ?? '{}',
          creadoEn: _desdeFecha(a['creado_en']),
        ),
    ]);
    poner(_base.bitacora, [
      for (final b in filas('bitacora'))
        BitacoraCompanion.insert(
          id: b['id']! as String,
          empresaId: empresaId,
          autorId: b['autor_id']! as String,
          entidad: b['entidad']! as String,
          entidadId: b['entidad_id']! as String,
          accion: _enum(AccionBitacora.values, b['accion']),
          valorAnterior: Value(_aTexto(b['valor_anterior'])),
          valorNuevo: Value(_aTexto(b['valor_nuevo'])),
          fecha: _desdeFecha(b['fecha']),
        ),
    ]);
  }

  /// Lo anotado en este teléfono ([local], como se sube) listo para sumarse
  /// a la cuenta que bajó ([cuenta]): las cuentas, categorías y proveedores
  /// se emparejan por tipo o nombre, y todo pasa a la empresa y al usuario de
  /// la cuenta. Lo que la cuenta ya tenía (el mismo comprobante, el mismo día
  /// cerrado, el mismo aviso visto) no se repite (entrega 14.4).
  static Map<String, Object?> _paraSumar(
    Map<String, Object?> local,
    Map<String, Object?> cuenta,
  ) {
    List<Map<String, Object?>> filas(Map<String, Object?> d, String tabla) => [
      for (final f in (d[tabla] as List? ?? const []))
        f as Map<String, Object?>,
    ];
    final usuarioId = (cuenta['usuario']! as Map)['id'];
    String clave(Object? texto) => '$texto'.trim().toLowerCase();

    // Cuentas por tipo; las que la cuenta no tiene se agregan.
    final cuentaPorTipo = {
      for (final c in filas(cuenta, 'cuentas')) c['tipo']: c['id'],
    };
    final cuentas = <Object?, Object?>{};
    final cuentasNuevas = <Map<String, Object?>>[];
    for (final c in filas(local, 'cuentas')) {
      if (cuentaPorTipo[c['tipo']] case final id?) {
        cuentas[c['id']] = id;
      } else {
        cuentas[c['id']] = c['id'];
        cuentasNuevas.add({
          ...c,
          'orden': cuentaPorTipo.length + cuentasNuevas.length,
        });
      }
    }

    // Categorías por nombre y tipo; proveedores por nombre.
    final categoriaPorNombre = {
      for (final c in filas(cuenta, 'categorias'))
        (clave(c['nombre']), c['tipo_movimiento']): c['id'],
    };
    final categorias = <Object?, Object?>{};
    final categoriasNuevas = <Map<String, Object?>>[];
    for (final c in filas(local, 'categorias')) {
      final id = categoriaPorNombre[(clave(c['nombre']), c['tipo_movimiento'])];
      categorias[c['id']] = id ?? c['id'];
      if (id == null) categoriasNuevas.add(c);
    }
    final contrapartePorNombre = {
      for (final c in filas(cuenta, 'contrapartes'))
        clave(c['nombre']): c['id'],
    };
    final contrapartes = <Object?, Object?>{};
    final contrapartesNuevas = <Map<String, Object?>>[];
    for (final c in filas(local, 'contrapartes')) {
      final id = contrapartePorNombre[clave(c['nombre'])];
      contrapartes[c['id']] = id ?? c['id'];
      if (id == null) contrapartesNuevas.add(c);
    }

    // Un comprobante que la cuenta ya tiene no se repite.
    String llaveComprobante(Map<String, Object?> c) => [
      c['emisor_identificacion'],
      c['tipo'],
      c['serie'],
      c['numero'],
    ].join('|');
    final comprobantePorLlave = {
      for (final c in filas(cuenta, 'comprobantes'))
        if (c['emisor_identificacion'] != null && c['numero'] != null)
          llaveComprobante(c): c['id'],
    };
    final comprobantes = <Object?, Object?>{};
    final comprobantesNuevos = <Map<String, Object?>>[];
    for (final c in filas(local, 'comprobantes')) {
      final id = comprobantePorLlave[llaveComprobante(c)];
      comprobantes[c['id']] = id ?? c['id'];
      if (id == null) comprobantesNuevos.add(c);
    }

    Object? mapa(Map<Object?, Object?> m, Object? id) =>
        id == null ? null : m[id] ?? id;
    final diasCerrados = {
      for (final d in filas(cuenta, 'dias_cerrados')) d['dia'],
    };
    final avisosVistos = {for (final a in filas(cuenta, 'alertas')) a['clave']};

    return {
      'cuentas': cuentasNuevas,
      'categorias': categoriasNuevas,
      'contrapartes': contrapartesNuevas,
      'comprobantes': comprobantesNuevos,
      'items_comprobante': [
        for (final i in filas(local, 'items_comprobante'))
          if (comprobantesNuevos.any((c) => c['id'] == i['comprobante_id'])) i,
      ],
      'movimientos': [
        for (final m in filas(local, 'movimientos'))
          {
            ...m,
            'autor_id': usuarioId,
            'cuenta_id': mapa(cuentas, m['cuenta_id']),
            'categoria_id': mapa(categorias, m['categoria_id']),
            'contraparte_id': mapa(contrapartes, m['contraparte_id']),
            'comprobante_id': mapa(comprobantes, m['comprobante_id']),
          },
      ],
      'arqueos': [
        for (final a in filas(local, 'arqueos')) {...a, 'autor_id': usuarioId},
      ],
      'arqueo_cuentas': [
        for (final a in filas(local, 'arqueo_cuentas'))
          {...a, 'cuenta_id': mapa(cuentas, a['cuenta_id'])},
      ],
      'dias_cerrados': [
        for (final d in filas(local, 'dias_cerrados'))
          if (!diasCerrados.contains(d['dia'])) d,
      ],
      'alertas': [
        for (final a in filas(local, 'alertas'))
          if (!avisosVistos.contains(a['clave'])) a,
      ],
      'bitacora': [
        for (final b in filas(local, 'bitacora')) {...b, 'autor_id': usuarioId},
      ],
    };
  }

  // --- Lo que se sube ------------------------------------------------------

  static String? _fecha(DateTime? d) => d?.toUtc().toIso8601String();

  static String? _dia(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

  static Object? _json(String? texto) =>
      texto == null ? null : jsonDecode(texto);

  Future<Map<String, Object>> _datosParaSubir(Empresa empresa) async {
    final id = empresa.id;
    final comprobantes = await (_base.select(
      _base.comprobantes,
    )..where((c) => c.empresaId.equals(id))).get();
    final arqueos = await (_base.select(
      _base.arqueos,
    )..where((a) => a.empresaId.equals(id))).get();
    final idsComprobantes = comprobantes.map((c) => c.id).toList();
    final idsArqueos = arqueos.map((a) => a.id).toList();
    return {
      'empresa': {
        'id': id,
        'nombre': empresa.nombre,
        'tipo_negocio': empresa.tipoNegocio.name,
        'modo': empresa.modo.name,
        'pais': empresa.pais,
        'moneda': empresa.moneda,
        'regimen': empresa.regimen,
        'hora_cierre_minutos': empresa.horaCierreMinutos,
        'identificacion_fiscal': empresa.identificacionFiscal,
        'creado_en': _fecha(empresa.creadoEn),
      },
      'cuentas': [
        for (final c in await _a.cuentas(id))
          {
            'id': c.id,
            'tipo': c.tipo.name,
            'nombre': c.nombre,
            'orden': c.orden,
            'saldo_inicial_centimos': c.saldoInicialCentimos,
            'fecha_saldo_inicial': _fecha(c.fechaSaldoInicial),
          },
      ],
      'categorias': [
        for (final c in await (_base.select(
          _base.categorias,
        )..where((c) => c.empresaId.equals(id))).get())
          {
            'id': c.id,
            'nombre': c.nombre,
            'tipo_movimiento': c.tipoMovimiento.name,
            'orden': c.orden,
            'activa': c.activa,
          },
      ],
      'contrapartes': [
        for (final c in await (_base.select(
          _base.contrapartes,
        )..where((c) => c.empresaId.equals(id))).get())
          {
            'id': c.id,
            'nombre': c.nombre,
            'identificacion_fiscal': c.identificacionFiscal,
            'tipo': c.tipo.name,
          },
      ],
      'comprobantes': [
        for (final c in comprobantes)
          {
            'id': c.id,
            'emisor_identificacion': c.emisorIdentificacion,
            'emisor_nombre': c.emisorNombre,
            'tipo': c.tipo,
            'serie': c.serie,
            'numero': c.numero,
            'fecha_emision': _dia(c.fechaEmision),
            'subtotal_centimos': c.subtotalCentimos,
            'impuesto_centimos': c.impuestoCentimos,
            'total_centimos': c.totalCentimos,
            'origen_lectura': c.origenLectura.name,
            'creado_en': _fecha(c.creadoEn),
          },
      ],
      'items_comprobante': [
        for (final i in await (_base.select(
          _base.itemsComprobante,
        )..where((i) => i.comprobanteId.isIn(idsComprobantes))).get())
          {
            'id': i.id,
            'comprobante_id': i.comprobanteId,
            'descripcion': i.descripcion,
            'cantidad': i.cantidad,
            'precio_unitario_centimos': i.precioUnitarioCentimos,
            'importe_centimos': i.importeCentimos,
          },
      ],
      'movimientos': [
        for (final m in await _a.movimientos(id))
          {
            'id': m.id,
            'tipo': m.tipo.name,
            'cuenta_id': m.cuentaId,
            'monto_centimos': m.montoCentimos,
            'fecha_movimiento': _fecha(m.fechaMovimiento),
            'fecha_comprobante': _fecha(m.fechaComprobante),
            'estado_pago': m.estadoPago.name,
            'monto_pagado_centimos': m.montoPagadoCentimos,
            'fecha_vencimiento': _fecha(m.fechaVencimiento),
            'fecha_pago': _fecha(m.fechaPago),
            'categoria_id': m.categoriaId,
            'contraparte_id': m.contraparteId,
            'comprobante_id': m.comprobanteId,
            'nivel_confianza': m.nivelConfianza.name,
            'fuente': m.fuente.name,
            'autor_id': m.autorId,
            'nota': m.nota,
            'estado': m.estado.name,
            'reemplaza_a': m.reemplazaA,
            'creado_en': _fecha(m.creadoEn),
          },
      ],
      'arqueos': [
        for (final a in arqueos)
          {
            'id': a.id,
            'fecha': _fecha(a.fecha),
            'autor_id': a.autorId,
            'creado_en': _fecha(a.creadoEn),
          },
      ],
      'arqueo_cuentas': [
        for (final a in await (_base.select(
          _base.arqueoCuentas,
        )..where((a) => a.arqueoId.isIn(idsArqueos))).get())
          {
            'id': a.id,
            'arqueo_id': a.arqueoId,
            'cuenta_id': a.cuentaId,
            'saldo_calculado_centimos': a.saldoCalculadoCentimos,
            'saldo_real_centimos': a.saldoRealCentimos,
            'diferencia_centimos': a.diferenciaCentimos,
            'motivo': a.motivo?.name,
            'movimiento_id': a.movimientoId,
          },
      ],
      'dias_cerrados': [
        for (final d in await (_base.select(
          _base.diasCerrados,
        )..where((d) => d.empresaId.equals(id))).get())
          {'id': d.id, 'dia': _dia(d.dia)},
      ],
      'alertas': [
        for (final a in await (_base.select(
          _base.alertas,
        )..where((a) => a.empresaId.equals(id))).get())
          {
            'id': _uuid.v5(id, a.id),
            'clave': a.id,
            'tipo': a.tipo,
            'prioridad': a.prioridad.name,
            'estado': a.estado.name,
            'texto': a.texto,
            'datos': _json(a.datos),
            'creado_en': _fecha(a.creadoEn),
          },
      ],
      // De la medición, solo los videos de ayuda abiertos (entrega 14.6).
      'videos_vistos': [
        for (final e
            in await (_base.select(_base.eventosMedicion)..where(
                  (e) => e.nombre.equals(EventoMedicion.videoAbierto.name),
                ))
                .get())
          if (_json(e.datos) case {
            'video': final int video,
            'desde': final desde,
          })
            {
              'id': e.id,
              'video': video,
              'desde': desde,
              'fecha': _fecha(e.fecha),
            },
      ],
      'bitacora': [
        for (final b in await (_base.select(
          _base.bitacora,
        )..where((b) => b.empresaId.equals(id))).get())
          {
            'id': b.id,
            'autor_id': b.autorId,
            'entidad': b.entidad,
            'entidad_id': b.entidadId,
            'accion': b.accion.name,
            'valor_anterior': _json(b.valorAnterior),
            'valor_nuevo': _json(b.valorNuevo),
            'fecha': _fecha(b.fecha),
          },
      ],
    };
  }
}
