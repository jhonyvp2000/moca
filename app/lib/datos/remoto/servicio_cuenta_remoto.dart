import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../dominio/errores.dart';
import '../../dominio/version.dart';
import '../../dominio/cobro.dart';
import '../../dominio/primer_dia.dart';
import '../../dominio/cuenta_real.dart';
import '../../dominio/equipo.dart';
import '../../dominio/medicion.dart';
import '../../dominio/modelos.dart';
import '../local/base_local.dart';
import '../local/categorias_al_dia.dart';
import '../repositorios/repositorio_errores_local.dart';
import '../repositorios/acceso_local.dart';
import '../repositorios/repositorio_tutoria_local.dart';

/// La dirección del servidor. Se cambia al compilar con
/// `--dart-define=MOCA_SERVIDOR=…`.
const direccionServidor = String.fromEnvironment(
  'MOCA_SERVIDOR',
  defaultValue: 'https://moca-servidor.onrender.com',
);

/// La cuenta real contra el servidor de Moca (servidor/README.md).
/// También lleva el equipo del negocio (entrega 19): usa la misma llave.
class ServicioCuentaRemoto
    implements
        ServicioCuenta,
        ServicioEquipo,
        ServicioCobro,
        ServicioPagos,
        ServicioVersion,
        ServicioErrores {
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
    await _guardarCobro(cuerpo);
  }

  /// El estado del cobro del negocio, si vino (entrega 25).
  Future<void> _guardarCobro(Map<String, Object?> cuerpo) async {
    if (cuerpo['cobro'] case final Map<String, Object?> cobro) {
      await _a.guardarAjuste(AccesoLocal.claveCobro, jsonEncode(cobro));
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
    bool invitado = false,
  }) async {
    if (!await _hayConexion()) return ResultadoVerificacion.sinSenal;
    final http.Response respuesta;
    try {
      respuesta = await _enviar('/cuenta/verificar', {
        'celular': celular,
        'codigo': codigo,
        if (entrar)
          'modo': 'entrar'
        else if (invitado) ...{
          // El invitado llega desde la Bienvenida, sin usuario todavía.
          'modo': 'invitado',
          'usuarioId': _uuid.v4(),
        } else ...{
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
    if (invitado) {
      switch (respuesta.statusCode) {
        case 200 when cuerpo['llave'] is String:
          await _llavero.guardar(cuerpo['llave']! as String);
          _celularPorEntrar = celular;
          _invitaciones = [
            for (final i in (cuerpo['invitaciones'] as List? ?? const []))
              _invitacionRecibida(i as Map<String, Object?>),
          ];
          return ResultadoVerificacion.verificado;
        case 404:
          return ResultadoVerificacion.sinInvitacion;
        case 400:
          return cuerpo['error'] == 'codigo_vencido'
              ? ResultadoVerificacion.vencido
              : ResultadoVerificacion.incorrecto;
        default:
          return ResultadoVerificacion.error;
      }
    }
    switch (respuesta.statusCode) {
      case 200:
        if (cuerpo['cuentaExistente'] == true || cuerpo['llave'] == null) {
          // El dueño elige qué hacer con el pase (entrega 14.4).
          _pase = cuerpo['pase'] as String?;
          _celularPorEntrar = celular;
          // Una cuenta sin ningún negocio (lo borró, o lo quitaron del
          // equipo) no tiene nada que juntar: lo de este teléfono se guarda
          // con el número, sin preguntar (entrega 14.4.1).
          final empresas = cuerpo['empresas'];
          if (!entrar &&
              _pase != null &&
              empresas is List &&
              empresas.isEmpty) {
            return empezarDeCero();
          }
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

  // --- El equipo (entrega 19) ---------------------------------------------

  List<InvitacionRecibida> _invitaciones = const [];

  @override
  List<InvitacionRecibida> get invitacionesRecibidas => _invitaciones;

  static Rol _rol(Object? nombre) => _enum(Rol.values, nombre);

  /// «+51987654321» → «987654321».
  static String _nueveDigitos(Object? celular) {
    final texto = '${celular ?? ''}';
    return texto.startsWith('+51') ? texto.substring(3) : texto;
  }

  static InvitacionRecibida _invitacionRecibida(Map<String, Object?> i) =>
      InvitacionRecibida(
        id: i['id']! as String,
        negocio: i['negocio'] as String? ?? '',
        rol: _rol(i['rol']),
        nombre: i['nombre'] as String?,
        venceEn: _desdeFecha(i['vence_en']),
      );

  static ResultadoEquipo _resultadoEquipo(http.Response r) {
    if (r.statusCode == 200) return ResultadoEquipo.listo;
    return switch (_cuerpo(r)['error']) {
      'sin_lugar' => ResultadoEquipo.sinLugar,
      'ya_esta' => ResultadoEquipo.yaEsta,
      'ya_tiene_negocio' => ResultadoEquipo.yaTieneNegocio,
      'invitacion_vencida' || 'sin_invitacion' => ResultadoEquipo.vencida,
      'sin_permiso' || 'sin_negocio' => ResultadoEquipo.sinPermiso,
      _ => ResultadoEquipo.error,
    };
  }

  /// La ruta con el negocio que se ve en el teléfono (`?empresa=`): quien
  /// está en varios (el contador) habla siempre de ese (entrega 22).
  Future<String> _delNegocio(String ruta) async {
    final empresa = await _a.empresa();
    if (empresa == null) return ruta;
    return '$ruta${ruta.contains('?') ? '&' : '?'}empresa=${empresa.id}';
  }

  /// Un pedido del equipo con la llave; nulo sin señal o sin llave.
  Future<http.Response?> _delEquipo(String ruta, [Object? cuerpo]) async {
    final llave = await _llavero.leer();
    if (llave == null || !await _hayConexion()) return null;
    final conNegocio = ruta.startsWith('/equipo')
        ? await _delNegocio(ruta)
        : ruta;
    try {
      return cuerpo == null
          ? await _pedir(conNegocio, llave)
          : await _enviar(conNegocio, cuerpo, llave: llave);
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    }
  }

  @override
  Future<Equipo?> equipo() async {
    final respuesta = await _delEquipo('/equipo');
    if (respuesta == null || respuesta.statusCode != 200) return null;
    final cuerpo = _cuerpo(respuesta);
    final yo = (await _a.usuarioONulo())?.id;
    return Equipo(
      miRol: _rol(cuerpo['rol']),
      maximo: cuerpo['maximo'] as int? ?? 3,
      personas: [
        for (final p in (cuerpo['personas'] as List? ?? const []))
          if (p case final Map<String, Object?> p)
            PersonaDelEquipo(
              membresiaId: p['membresia_id']! as String,
              usuarioId: p['usuario_id']! as String,
              rol: _rol(p['rol']),
              nombre: p['nombre'] as String?,
              celular: p['celular'] == null
                  ? null
                  : _nueveDigitos(p['celular']),
              titular: p['titular'] == true,
              soyYo: p['usuario_id'] == yo,
              cajas: [
                for (final c in (p['cajas'] as List? ?? const [])) c as String,
              ],
            ),
      ],
      invitaciones: [
        for (final i in (cuerpo['invitaciones'] as List? ?? const []))
          if (i case final Map<String, Object?> i)
            InvitacionPendiente(
              id: i['id']! as String,
              celular: _nueveDigitos(i['celular']),
              rol: _rol(i['rol']),
              nombre: i['nombre'] as String?,
              venceEn: _desdeFecha(i['vence_en']),
            ),
      ],
    );
  }

  @override
  Future<ResultadoEquipo> invitar({
    required String celular,
    required Rol rol,
    String? nombre,
  }) async {
    final r = await _delEquipo('/equipo/invitar', {
      'celular': celular,
      'rol': rol.name,
      if (nombre != null && nombre.trim().isNotEmpty) 'nombre': nombre.trim(),
    });
    return r == null ? ResultadoEquipo.sinSenal : _resultadoEquipo(r);
  }

  @override
  Future<ResultadoEquipo> anular(String invitacionId) async {
    final r = await _delEquipo('/equipo/anular', {'invitacion': invitacionId});
    return r == null ? ResultadoEquipo.sinSenal : _resultadoEquipo(r);
  }

  @override
  Future<ResultadoEquipo> quitar(String membresiaId) async {
    final r = await _delEquipo('/equipo/quitar', {'membresia': membresiaId});
    return r == null ? ResultadoEquipo.sinSenal : _resultadoEquipo(r);
  }

  @override
  Future<({MisPagos? pagos, bool alDia})> misPagos() async {
    final r = await _delEquipo(await _delNegocio('/cobro/mis-pagos'));
    if (r != null && r.statusCode == 200) {
      final ahora = _a.ahora();
      await _a.guardarAjuste(
        AccesoLocal.claveMisPagos,
        jsonEncode({'actualizado': ahora.toIso8601String(), ..._cuerpo(r)}),
      );
      return (pagos: MisPagos.desdeServidor(_cuerpo(r), ahora), alDia: true);
    }
    final guardado = await _a.leerAjuste(AccesoLocal.claveMisPagos);
    if (guardado == null) return (pagos: null, alDia: false);
    try {
      final json = jsonDecode(guardado) as Map<String, Object?>;
      return (
        pagos: MisPagos.desdeServidor(
          json,
          DateTime.tryParse(json['actualizado'] as String? ?? '') ?? _a.ahora(),
        ),
        alDia: false,
      );
    } on FormatException {
      return (pagos: null, alDia: false);
    }
  }

  @override
  Future<ResultadoInicioDePago> pagarConMercadoPago() async {
    final r = await _delEquipo(await _delNegocio('/cobro/mercadopago'), {});
    if (r == null) return (inicio: null, error: ErrorDePago.sinSenal);
    final cuerpo = _cuerpo(r);
    if (r.statusCode == 200 &&
        cuerpo['orden'] is String &&
        cuerpo['enlace'] is String) {
      return (
        inicio: InicioDePago(
          orden: cuerpo['orden']! as String,
          enlace: cuerpo['enlace']! as String,
        ),
        error: null,
      );
    }
    return (
      inicio: null,
      error: switch (cuerpo['error']) {
        'sin_mercadopago' || 'sin_cobro' => ErrorDePago.noDisponible,
        'solo_duenos' => ErrorDePago.soloDuenos,
        _ => ErrorDePago.fallo,
      },
    );
  }

  @override
  Future<OrdenDePago> estadoDeOrden(String orden) async {
    final r = await _delEquipo('/cobro/orden/${Uri.encodeComponent(orden)}');
    if (r == null || r.statusCode != 200) {
      return (estado: EstadoDeOrden.sinSenal, hasta: null);
    }
    final cuerpo = _cuerpo(r);
    // Ya pagado: el cobro nuevo queda en el teléfono al instante.
    await _guardarCobro(cuerpo);
    final cobro = cuerpo['cobro'];
    return (
      estado: switch (cuerpo['estado']) {
        'pagada' => EstadoDeOrden.pagada,
        'revisar' => EstadoDeOrden.revisar,
        'reembolsada' => EstadoDeOrden.reembolsada,
        _ => EstadoDeOrden.pendiente,
      },
      hasta: cobro is Map<String, Object?>
          ? Cobro.desdeServidor(cobro).hasta
          : null,
    );
  }

  @override
  Future<ResultadoEquipo> responderPrecio(
    RespuestaPrecio respuesta, {
    String? motivo,
  }) async {
    final r = await _delEquipo(await _delNegocio('/cobro/respuesta'), {
      'respuesta': switch (respuesta) {
        RespuestaPrecio.si => 'si',
        RespuestaPrecio.noSe => 'no_se',
        RespuestaPrecio.no => 'no',
      },
      if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
    });
    if (r == null) return ResultadoEquipo.sinSenal;
    final resultado = _resultadoEquipo(r);
    // Ya no se vuelve a preguntar en este teléfono.
    if (resultado == ResultadoEquipo.listo) {
      final guardado = await _a.leerAjuste(AccesoLocal.claveCobro);
      final cobro = guardado == null
          ? <String, Object?>{}
          : jsonDecode(guardado) as Map<String, Object?>;
      await _a.guardarAjuste(
        AccesoLocal.claveCobro,
        jsonEncode({...cobro, 'respondio': true}),
      );
    }
    return resultado;
  }

  // --- Los errores de la app (entrega 27) -----------------------------------

  late final _errores = RepositorioErroresLocal(_base, ahora: _a.ahora);

  @override
  Future<bool> subirErrores() async {
    // Con los errores sube también lo que mide la app (entrega 28).
    await subirUso();
    final lista = await _errores.porSubir();
    if (lista.isEmpty) return true;
    final llave = await _llavero.leer();
    if (llave == null || await _bloqueada() || !await _hayConexion()) {
      return false;
    }
    try {
      final r = await _enviar('/errores', {
        'errores': [for (final e in lista.take(50)) e.json()],
      }, llave: llave);
      if (r.statusCode != 200) return false;
      await _errores.quitar({for (final e in lista.take(50)) e.id});
      return true;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    }
  }

  // --- Lo que mide la app (entrega 28) ---------------------------------------

  static const _claveUsoHasta = 'uso_subido_hasta';

  /// Sube lo que mide la app, de a 500, desde lo último que subió.
  Future<bool> subirUso() async {
    if (await _a.enDemo()) return true;
    final llave = await _llavero.leer();
    if (llave == null ||
        await _a.leerAjuste(AccesoLocal.claveCuentaVerificada) == null ||
        await _bloqueada() ||
        !await _hayConexion()) {
      return false;
    }
    // Hasta dónde subió, y los de ese mismo segundo que ya subieron.
    DateTime? desde;
    var yaSubidos = <String>{};
    try {
      final guardado = jsonDecode(
        await _a.leerAjuste(_claveUsoHasta) ?? '{}',
      ) as Map<String, Object?>;
      desde = DateTime.tryParse(guardado['fecha'] as String? ?? '');
      yaSubidos = {
        for (final id in guardado['ids'] as List? ?? const []) id as String,
      };
    } on FormatException {
      desde = null;
    }
    final eventos = [
      for (final e
          in await (_base.select(_base.eventosMedicion)
                ..where(
                  (e) => desde == null
                      ? const Constant(true)
                      : e.fecha.isBiggerOrEqualValue(desde),
                )
                ..orderBy([(e) => OrderingTerm.asc(e.fecha)])
                ..limit(500 + yaSubidos.length))
              .get())
        if (!yaSubidos.contains(e.id)) e,
    ].take(500).toList();
    if (eventos.isEmpty) return true;
    try {
      final r = await _enviar('/uso', {
        'eventos': [
          for (final e in eventos)
            {
              'id': e.id,
              'nombre': e.nombre,
              'fecha': _fecha(e.fecha),
              'datos': ?_json(e.datos),
            },
        ],
      }, llave: llave);
      if (r.statusCode != 200) return false;
      final ultima = eventos.last.fecha;
      await _a.guardarAjuste(
        _claveUsoHasta,
        jsonEncode({
          'fecha': ultima.toIso8601String(),
          'ids': [
            if (ultima == desde) ...yaSubidos,
            for (final e in eventos)
              if (e.fecha == ultima) e.id,
          ],
        }),
      );
      return true;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    }
  }

  @override
  Future<List<ErrorAgrupado>?> errores() async {
    final r = await _delEquipo('/errores');
    if (r == null || r.statusCode != 200) return null;
    return [
      for (final e in (_cuerpo(r)['errores'] as List? ?? const []))
        if (e case final Map<String, Object?> e)
          ErrorAgrupado(
            mensaje: e['mensaje'] as String? ?? '',
            veces: e['veces'] as int? ?? 0,
            negocios: e['negocios'] as int? ?? 0,
            personas: e['personas'] as int? ?? 0,
            ultima:
                DateTime.tryParse(e['ultima'] as String? ?? '')?.toLocal() ??
                DateTime(2000),
            pila: e['pila'] as String?,
            pantalla: e['pantalla'] as String?,
            entrega: e['entrega'] as String?,
            armado: e['armado'] as int?,
          ),
    ];
  }

  // --- La versión nueva (entrega 26.3) --------------------------------------

  @override
  Future<EstadoDeVersion?> buscarVersion({required bool todas}) async {
    if (!await _hayConexion()) return null;
    try {
      final r = await _cliente
          .get(
            _servidor.resolve(
              todas ? '/app/version?canal=todas' : '/app/version',
            ),
          )
          .timeout(_espera);
      if (r.statusCode != 200) return null;
      final cuerpo = _cuerpo(r);
      final ultima = cuerpo['ultima'];
      return EstadoDeVersion(
        minima: cuerpo['minima'] as int?,
        ultima: ultima is Map<String, Object?>
            ? VersionPublicada(
                nombre: ultima['nombre'] as String? ?? '',
                armado: ultima['armado'] as int? ?? 0,
                arm64: ultima['arm64'] as String?,
                v7a: ultima['v7a'] as String?,
              )
            : null,
      );
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    }
  }

  // --- La pantalla de cobros (entrega 26) ---------------------------------

  static DateTime? _leerDia(Object? valor) =>
      valor is String ? DateTime.tryParse(valor) : null;

  static UsoDelNegocio? _uso(Object? u) => u is Map<String, Object?>
      ? UsoDelNegocio(
          diasQueAbrio: u['dias_que_abrio'] as int? ?? 0,
          diasQueAnoto: u['dias_que_anoto'] as int? ?? 0,
          ventasAnotadas: u['ventas_anotadas'] as int? ?? 0,
          segundosParaAnotar: u['segundos_para_anotar'] as int?,
          vozConDuda: u['voz_con_duda'] as int? ?? 0,
          vozCorregida: u['voz_corregida'] as int? ?? 0,
          fotosIlegibles: u['fotos_ilegibles'] as int? ?? 0,
          avisosRespondidos: u['avisos_respondidos'] as int? ?? 0,
          avisosAbiertos: u['avisos_abiertos'] as int? ?? 0,
          arqueosAbiertos: u['arqueos_abiertos'] as int? ?? 0,
          informesAbiertos: u['informes_abiertos'] as int? ?? 0,
          ultimaApertura: DateTime.tryParse(
            u['ultima_apertura'] as String? ?? '',
          )?.toLocal(),
        )
      : null;

  static FichaDeCobro _ficha(Map<String, Object?> f) => FichaDeCobro(
    uso: _uso(f['uso']),
    ultimaApertura: DateTime.tryParse(f['ultima_apertura'] as String? ?? '')
        ?.toLocal(),
    empresaId: f['empresa_id']! as String,
    nombre: f['nombre'] as String? ?? '',
    celular: f['celular'] as String?,
    cobro: Cobro.desdeServidor(f['cobro'] as Map<String, Object?>? ?? const {}),
    pagos: [
      for (final p in (f['pagos'] as List? ?? const []))
        if (p case final Map<String, Object?> p)
          PagoRegistrado(
            id: p['id'] as String? ?? '',
            anulado: p['anulado_en'] != null,
            plan: PlanCobro.values.asNameMap()[p['plan']] ?? PlanCobro.normal,
            montoCentimos: p['monto_centimos'] as int? ?? 0,
            desde: _leerDia(p['desde']) ?? DateTime(2000),
            hasta: _leerDia(p['hasta']) ?? DateTime(2000),
            nota: p['nota'] as String?,
          ),
    ],
    respuestas: [
      for (final r in (f['respuestas'] as List? ?? const []))
        if (r case final Map<String, Object?> r)
          RespuestaRegistrada(
            respuesta: switch (r['respuesta']) {
              'si' => RespuestaPrecio.si,
              'no' => RespuestaPrecio.no,
              _ => RespuestaPrecio.noSe,
            },
            motivo: r['motivo'] as String?,
            precioCentimos: r['precio_centimos'] as int? ?? 0,
          ),
    ],
  );

  static ResultadoCobro _resultadoCobro(http.Response r) =>
      switch (r.statusCode) {
        200 => ResultadoCobro.listo,
        403 => ResultadoCobro.sinPermiso,
        404 => ResultadoCobro.noEncontrado,
        409 when _cuerpo(r)['error'] == 'perdio_fundador' =>
          ResultadoCobro.perdioFundador,
        409 when _cuerpo(r)['error'] == 'no_es_el_ultimo' =>
          ResultadoCobro.noEsElUltimo,
        409 => ResultadoCobro.sinCupoFundador,
        _ => ResultadoCobro.error,
      };

  @override
  Future<ResumenDeCobros?> resumen() async {
    final r = await _delEquipo('/cobro/resumen');
    if (r == null || r.statusCode != 200) return null;
    final cuerpo = _cuerpo(r);
    final fundadores = cuerpo['fundadores'] as Map<String, Object?>? ?? {};
    return ResumenDeCobros(
      fundadores: fundadores['usados'] as int? ?? 0,
      maximoFundadores: fundadores['maximo'] as int? ?? 50,
      negocios: [
        for (final n in (cuerpo['negocios'] as List? ?? const []))
          _ficha(n as Map<String, Object?>),
      ],
      sinAbrir: [
        for (final n in (cuerpo['sin_abrir'] as List? ?? const []))
          _ficha(n as Map<String, Object?>),
      ],
      porRevisar: [
        for (final o in (cuerpo['revisar'] as List? ?? const []))
          if (o is Map<String, Object?>)
            PagoPorRevisar(
              nombre: o['nombre'] as String? ?? '',
              celular: o['celular'] as String?,
              motivo: o['motivo'] as String? ?? '',
              operacion: o['mp_pago_id'] as String?,
              montoCentimos: o['monto_centimos'] as int? ?? 0,
            ),
      ],
    );
  }

  @override
  Future<(FichaDeCobro?, ResultadoCobro)> buscar(String celular) async {
    final r = await _delEquipo(
      '/cobro/negocio?celular=${Uri.encodeQueryComponent(celular)}',
    );
    if (r == null) return (null, ResultadoCobro.sinSenal);
    final resultado = _resultadoCobro(r);
    return resultado == ResultadoCobro.listo
        ? (_ficha(_cuerpo(r)), resultado)
        : (null, resultado);
  }

  @override
  Future<(FichaDeCobro?, ResultadoCobro)> anularPago(String pagoId) async {
    final r = await _delEquipo('/cobro/anular', {'pago': pagoId});
    if (r == null) return (null, ResultadoCobro.sinSenal);
    final resultado = _resultadoCobro(r);
    return resultado == ResultadoCobro.listo
        ? (_ficha(_cuerpo(r)), resultado)
        : (null, resultado);
  }

  @override
  Future<(FichaDeCobro?, ResultadoCobro)> registrarPago(
    String empresaId,
    PlanCobro plan, {
    String? nota,
  }) async {
    final r = await _delEquipo('/cobro/pago', {
      'empresa': empresaId,
      'plan': plan.name,
      if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
    });
    if (r == null) return (null, ResultadoCobro.sinSenal);
    final resultado = _resultadoCobro(r);
    return resultado == ResultadoCobro.listo
        ? (_ficha(_cuerpo(r)), resultado)
        : (null, resultado);
  }

  @override
  Future<ResultadoEquipo> salir() async {
    // Lo que anotó y falta subir sube antes: después ya no podrá.
    if (await hayCambiosSinSubir() && !await subirTodo()) {
      return ResultadoEquipo.sinSenal;
    }
    final r = await _delEquipo('/equipo/salir', const <String, Object?>{});
    if (r == null) return ResultadoEquipo.sinSenal;
    final resultado = _resultadoEquipo(r);
    if (resultado == ResultadoEquipo.listo) {
      // Su copia del negocio se borra (entrega 37).
      await _perderAcceso(MotivoSinAcceso.salio);
    }
    return resultado;
  }

  @override
  Future<ResultadoEquipo> asignarCajas(
    String membresiaId,
    List<String> cuentaIds,
  ) async {
    final r = await _delEquipo('/equipo/cajas', {
      'membresia': membresiaId,
      'cajas': cuentaIds,
    });
    return r == null ? ResultadoEquipo.sinSenal : _resultadoEquipo(r);
  }

  @override
  Future<ResultadoEquipo> aceptar(String invitacionId) async {
    final r = await _delEquipo('/cuenta/aceptar', {
      'invitacion': invitacionId,
      'consentimiento': true,
    });
    if (r == null) return ResultadoEquipo.sinSenal;
    final resultado = _resultadoEquipo(r);
    if (resultado != ResultadoEquipo.listo) return resultado;
    // Ya es parte del negocio: baja lo que su rol puede ver, de ese negocio.
    final empresaId = _cuerpo(r)['empresa_id'];
    if (empresaId is String) return cambiarDeNegocio(empresaId);
    return switch (await bajarTodo()) {
      ResultadoBajada.listo => ResultadoEquipo.listo,
      ResultadoBajada.sinSenal => ResultadoEquipo.sinSenal,
      _ => ResultadoEquipo.error,
    };
  }

  @override
  Future<List<NegocioDelUsuario>?> misNegocios() async {
    final r = await _delEquipo('/cuenta/negocios');
    if (r == null || r.statusCode != 200) return null;
    final actual = (await _a.empresa())?.id;
    return [
      for (final n in (_cuerpo(r)['negocios'] as List? ?? const []))
        if (n case final Map<String, Object?> n)
          NegocioDelUsuario(
            empresaId: n['empresa_id']! as String,
            nombre: n['nombre'] as String? ?? '',
            rol: _rol(n['rol']),
            actual: n['empresa_id'] == actual,
          ),
    ];
  }

  @override
  Future<ResultadoEquipo> cambiarDeNegocio(String empresaId) async {
    final llave = await _llavero.leer();
    final celular =
        _celularPorEntrar ??
        await _a.leerAjuste(AccesoLocal.claveCuentaVerificada);
    if (llave == null || celular == null) return ResultadoEquipo.error;
    if (!await _hayConexion()) return ResultadoEquipo.sinSenal;
    // Lo de este teléfono que falta subir, antes de reemplazarlo: un dueño
    // que también es contador de otro negocio no pierde nada. A quien
    // quitaron ya no le sube nada (entrega 22.1).
    // Sin acceso (entrega 37), el teléfono ya no tiene negocio que subir.
    if (await _a.empresa() != null &&
        await _a.leerAjuste(AccesoLocal.claveCuentaVerificada) != null &&
        await _a.leerAjuste(_claveFuera) == null &&
        await hayCambiosSinSubir() &&
        !await subirTodo()) {
      return ResultadoEquipo.sinSenal;
    }
    final http.Response respuesta;
    try {
      respuesta = await _pedir('/datos/bajar?empresa=$empresaId', llave);
    } on TimeoutException {
      return ResultadoEquipo.sinSenal;
    } on http.ClientException {
      return ResultadoEquipo.sinSenal;
    }
    if (respuesta.statusCode != 200) return ResultadoEquipo.error;
    final cuerpo = _cuerpo(respuesta);
    final datos = cuerpo['datos'];
    if (datos is! Map<String, Object?>) return ResultadoEquipo.sinPermiso;
    await _guardarBajada(datos, celular);
    await _guardarCifras(cuerpo, await _a.huella());
    _celularPorEntrar = null;
    return ResultadoEquipo.listo;
  }

  @override
  Future<List<InvitacionRecibida>?> buscarInvitaciones() async {
    final r = await _delEquipo('/cuenta/invitaciones');
    if (r == null || r.statusCode != 200) return null;
    return _invitaciones = [
      for (final i in (_cuerpo(r)['invitaciones'] as List? ?? const []))
        _invitacionRecibida(i as Map<String, Object?>),
    ];
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
    await _guardarCobro(cuerpo);
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
        // La cuenta se abrió en otro teléfono (entrega 37: se borra la copia).
        await _perderAcceso(MotivoSinAcceso.otroTelefono);
        return false;
      }
      final cuerpo = _cuerpo(respuesta);
      if (respuesta.statusCode == 403 && _sinAcceso(cuerpo['error'])) {
        await _perderAcceso(SinAcceso.delServidor(cuerpo['error']));
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
      final respuesta = await _pedir(await _delNegocio('/cifras'), llave);
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

  /// Las respuestas del servidor que dicen que este teléfono ya no ve el
  /// negocio (entrega 37).
  static bool _sinAcceso(Object? error) =>
      error == 'negocio_borrado' ||
      error == 'quitado' ||
      error == 'sin_negocio' ||
      error == 'no_es_tu_empresa';

  /// Este teléfono perdió el acceso (entrega 37): se borra su copia del
  /// negocio y solo queda qué pasó. La cuenta sigue (salvo si se abrió en
  /// otro teléfono), para ver otros negocios o invitaciones.
  Future<void> _perderAcceso(MotivoSinAcceso motivo) async {
    final negocio = (await _a.empresa())?.nombre ?? '';
    final celular = await _a.leerAjuste(AccesoLocal.claveCuentaVerificada);
    await _base.transaction(() async {
      await _base.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final tabla in _base.allTables) {
        await _base.delete(tabla).go();
      }
      await _a.guardarAjuste('etapa', EtapaInicio.sinAcceso.name);
      await _a.guardarAjuste(
        AccesoLocal.claveSinAcceso,
        jsonEncode({'motivo': motivo.name, 'negocio': negocio}),
      );
      if (motivo != MotivoSinAcceso.otroTelefono && celular != null) {
        await _a.guardarAjuste(AccesoLocal.claveCuentaVerificada, celular);
      }
    });
  }

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
      final respuesta = await _pedir(
        await _delNegocio('/datos/cambios?desde=$desde'),
        llave,
      );
      if (respuesta.statusCode == 401) {
        await _perderAcceso(MotivoSinAcceso.otroTelefono);
        return false;
      }
      final cuerpo = _cuerpo(respuesta);
      if (respuesta.statusCode == 403 && _sinAcceso(cuerpo['error'])) {
        await _perderAcceso(SinAcceso.delServidor(cuerpo['error']));
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
        await _guardarEquipo(cuerpo);
        await _guardarCobro(cuerpo);
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

  /// Quiénes están en el negocio, para «Lo anotó Rosa» (entrega 20), y las
  /// cajas a cargo de quien usa el teléfono (entrega 21).
  Future<void> _guardarEquipo(Map<String, Object?> datos) async {
    if (datos['equipo'] case final List equipo) {
      await _a.guardarAjuste(AccesoLocal.claveEquipo, jsonEncode(equipo));
    }
    final membresia = datos['membresia'];
    final cajas = datos.containsKey('mis_cajas')
        ? datos['mis_cajas']
        : membresia is Map
        ? membresia['cajas']
        : null;
    if (datos.containsKey('mis_cajas') ||
        (membresia is Map && membresia.containsKey('cajas'))) {
      if (cajas is List) {
        await _a.guardarAjuste(AccesoLocal.claveMisCajas, jsonEncode(cajas));
      } else {
        await (_base.delete(
          _base.ajustes,
        )..where((a) => a.clave.equals(AccesoLocal.claveMisCajas))).go();
      }
    }
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
      await _guardarEquipo(datos);
      final equipo = datos['equipo'];
      if (equipo is List) {
        await _a.guardarAjuste(_clavePersonas, '${equipo.length}');
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
      await ponerAlDiaCategorias(_base);

      // Una cuenta que se guardó antes del alta sigue en el alta.
      final conAlta = (empresa['nombre']! as String).isNotEmpty;
      await _a.guardarAjuste('etapa', conAlta ? 'listo' : 'alta');
      await _a.guardarAjuste(AccesoLocal.claveCuentaVerificada, celular);
      for (final clave in [
        _claveSinCuentaDesde,
        _claveCerrada,
        _claveFuera,
        AccesoLocal.claveSinAcceso,
      ]) {
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
          cuentaDestinoId: Value(m['cuenta_destino_id'] as String?),
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
            'cuenta_destino_id': mapa(cuentas, m['cuenta_destino_id']),
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
          // Lo de la persona simulada del ajuste oculto no se sube.
          if (m.autorId != AccesoLocal.usuarioSimulado)
            {
              'id': m.id,
              'tipo': m.tipo.name,
              'cuenta_id': m.cuentaId,
              'cuenta_destino_id': m.cuentaDestinoId,
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
