import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../dominio/cuenta_real.dart';
import '../../dominio/medicion.dart';
import '../../dominio/modelos.dart';
import '../local/base_local.dart';
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
      return SituacionCuenta(
        estado: EstadoCuenta.guardada,
        celular: verificado,
      );
    }
    final usuarios = await _base.select(_base.usuarios).get();
    final celular = usuarios.firstOrNull?.celular;
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
    if (await _a.leerAjuste(_claveCerrada) != null) return false;
    final llave = await _llavero.leer();
    if (llave == null) return false;
    _subiendo = true;
    try {
      final empresa = await _a.empresa();
      if (empresa == null) return false;
      final datos = await _datosParaSubir(empresa);
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
      if (respuesta.statusCode != 200) return false;
      final cuerpo = _cuerpo(respuesta);
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
    if (await _a.enDemo() || await _a.leerAjuste(_claveCerrada) != null) return;
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
      await _base.batch((lote) => _insertarFilas(lote, datos, empresaId));
      await _recordarVideosVistos(datos);
      // Lo que acaba de bajar ya está en el servidor.
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

      // Una cuenta que se guardó antes del alta sigue en el alta.
      final conAlta = (empresa['nombre']! as String).isNotEmpty;
      await _a.guardarAjuste('etapa', conAlta ? 'listo' : 'alta');
      await _a.guardarAjuste(AccesoLocal.claveCuentaVerificada, celular);
      for (final clave in [_claveSinCuentaDesde, _claveCerrada]) {
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
  void _insertarFilas(
    Batch lote,
    Map<String, Object?> datos,
    String empresaId, {
    EstadoSincronizacion estado = EstadoSincronizacion.subido,
  }) {
    List<Map<String, Object?>> filas(String tabla) => [
      for (final f in (datos[tabla] as List? ?? const []))
        f as Map<String, Object?>,
    ];
    lote.insertAll(_base.cuentas, [
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
    lote.insertAll(_base.categorias, [
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
    lote.insertAll(_base.contrapartes, [
      for (final c in filas('contrapartes'))
        ContrapartesCompanion.insert(
          id: c['id']! as String,
          empresaId: empresaId,
          nombre: c['nombre']! as String,
          identificacionFiscal: Value(c['identificacion_fiscal'] as String?),
          tipo: _enum(TipoContraparte.values, c['tipo']),
        ),
    ]);
    lote.insertAll(_base.comprobantes, [
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
    lote.insertAll(_base.itemsComprobante, [
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
    lote.insertAll(_base.movimientos, [
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
    lote.insertAll(_base.arqueos, [
      for (final a in filas('arqueos'))
        ArqueosCompanion.insert(
          id: a['id']! as String,
          empresaId: empresaId,
          fecha: _desdeFecha(a['fecha']),
          autorId: a['autor_id']! as String,
          creadoEn: _desdeFecha(a['creado_en']),
        ),
    ]);
    lote.insertAll(_base.arqueoCuentas, [
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
    lote.insertAll(_base.diasCerrados, [
      for (final d in filas('dias_cerrados'))
        DiasCerradosCompanion.insert(
          id: d['id']! as String,
          empresaId: empresaId,
          dia: _desdeDia(d['dia'])!,
        ),
    ]);
    // Los avisos marcados «Entendido»: en el teléfono, su id es la clave.
    lote.insertAll(_base.alertas, [
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
    lote.insertAll(_base.bitacora, [
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
