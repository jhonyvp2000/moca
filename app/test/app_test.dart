import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:drift/drift.dart'
    show DatabaseConnection, Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moca/app.dart';
import 'package:moca/comun/barra_inferior.dart';
import 'package:moca/comun/estructura.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/acceso_local.dart';
import 'package:moca/datos/remoto/servicio_cuenta_remoto.dart';
import 'package:moca/datos/repositorios/repositorio_comprobantes_local.dart';
import 'package:moca/datos/repositorios/repositorio_movimientos_local.dart';
import 'package:moca/datos/repositorios/repositorio_operador_local.dart';
import 'package:moca/datos/repositorios/repositorio_primer_dia_local.dart';
import 'package:moca/datos/simulados/lector_foto_simulado.dart';
import 'package:moca/dominio/version.dart';
import 'package:moca/dominio/cobro.dart';
import 'package:moca/dominio/cerradura.dart';
import 'package:moca/dominio/aviso_cierre.dart';
import 'package:moca/dominio/comprobantes.dart';
import 'package:moca/dominio/conexion.dart';
import 'package:moca/dominio/cuenta_real.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/dominio/movimientos.dart';
import 'package:moca/dominio/primer_dia.dart';
import 'package:moca/dominio/servicios.dart';
import 'package:moca/dominio/tutoria.dart';
import 'package:moca/dominio/voz.dart';
import 'package:moca/inyeccion.dart';
import 'package:moca/pais/peru/formato.dart';
import 'package:moca/dominio/historial.dart';
import 'package:moca/dominio/informe.dart';
import 'package:moca/pantallas/historial/fila_movimiento.dart';
import 'package:moca/pantallas/informe/pdf_informe.dart';
import 'package:moca/pais/peru/categorias.dart';
import 'package:moca/pantallas/moca/pantalla_moca.dart';
import 'package:moca/rutas.dart';
import 'package:moca/textos/textos.dart';
import 'package:go_router/go_router.dart';

final _ahoraInicial = DateTime(2026, 10, 12, 21, 5);
var _ahora = _ahoraInicial;

/// Lo que «dice» el dueño en la próxima grabación.
var _loQueDice = [const AlternativaVoz('hola')];
var _vozDisponible = DisponibilidadVoz.disponible;

/// Si el teléfono «tiene señal».
var _conSenal = true;

class _SenalFalsa implements Conexion {
  @override
  Future<bool> hayConexion() async => _conSenal;

  @override
  Stream<bool> observar() => Stream.value(_conSenal);
}

/// Lo que leyó la voz sintética y si el teléfono «tiene» voz en español.
final _loQueDijo = <String>[];
var _hayVoz = true;

class _LocutorFalso implements Locutor {
  @override
  Future<bool> disponible() async => _hayVoz;

  @override
  Future<void> decir(String texto) async => _loQueDijo.add(texto);

  @override
  Future<void> detener() async {}
}

class _CompartidorFalso implements Compartidor {
  @override
  Future<void> compartirArchivo(
    String ruta, {
    required String asunto,
    String tipo = 'application/pdf',
  }) async {}

  @override
  Future<void> compartirArchivos(
    List<(String, String)> archivos, {
    required String asunto,
  }) async {}
}

/// Lo último que se programó y si el dueño da el permiso de avisos.
var _programado = <NotificacionProgramada>[];
var _daPermiso = true;
void Function(DestinoNotificacion)? _abrirDesdeAviso;

class _NotificadorFalso implements Notificador {
  @override
  Future<void> iniciar({
    required void Function(DestinoNotificacion destino) alAbrir,
  }) async => _abrirDesdeAviso = alAbrir;

  @override
  Future<bool> pedirPermiso() async => _daPermiso;

  @override
  Future<void> programar(List<NotificacionProgramada> plan) async =>
      _programado = plan;

  @override
  Future<void> probarAvisoCierre() async => _avisosDePrueba++;

  @override
  Future<AvisosGuardados> guardados() async =>
      AvisosGuardados(alAbrir: 0, ahora: [for (final n in _programado) n.id]);
}

var _avisosDePrueba = 0;

/// El servidor de Moca, simulado: «123456» entra y «000000» venció.
class _ServidorFalso {
  final subidas = <Map<String, Object?>>[];
  final codigosPedidos = <String>[];
  final marcasPedidas = <Object?>[];
  int estadoAlPedir = 200;
  bool cuentaExistente = false;

  /// La cuenta del número ya no tiene ningún negocio (entrega 14.4.1).
  bool cuentaSinNegocio = false;

  /// Lo que se eligió con el pase (entrega 14.4).
  final conPase = <String>[];

  /// Lo que baja «Ya tengo cuenta»; nulo: el número no tiene cuenta.
  Map<String, Object?>? cuentaParaEntrar;

  /// La próxima bajada se corta a medio camino.
  bool cortarBajada = false;

  /// La cuenta se abrió en otro teléfono: la llave de este ya no sirve.
  bool sesionRevocada = false;

  /// Lo que pidió borrar en el servidor (entrega 14.8).
  final borrados = <Object?>[];

  /// Cuántas veces se pidió lo nuevo de los demás (entrega 18.1).
  var pedidosDeCambios = 0;

  /// Cuántas veces alguien salió del negocio (entrega 22.2).
  var salidas = 0;

  /// Lo que responde «/app/version» (entrega 26.3), y con qué canal se pidió.
  Map<String, Object?> version = {'ultima': null, 'minima': null};
  final canalesPedidos = <String?>[];

  /// La pregunta del día 10 (entrega 25).
  final respuestasDePrecio = <Map<String, Object?>>[];

  /// La pantalla de cobros (entrega 26): los pagos que se registraron y
  /// los que se anularon (26.1).
  final pagos = <Map<String, Object?>>[];

  /// Por qué este teléfono ya no ve el negocio (entrega 37).
  String? sinAccesoAlNegocio;

  /// Mercado Pago (entrega 32): el error al pedir pagar y cómo va la orden.
  String? errorMercadoPago;
  var ordenesPedidas = 0;

  /// Los días de prueba que se dieron desde soporte (entrega 47).
  final diasDados = <Object?>[];

  /// Lo que pidió la app al pagar con Mercado Pago (entrega 43).
  Map<String, Object?>? ultimaOrden;
  var consultasDeOrden = 0;
  Map<String, Object?> orden = {'estado': 'pendiente'};
  final anulados = <Object?>[];

  Map<String, Object?> fichaDeLucho({String? hasta}) => {
    'empresa_id': 'empresa-lucho',
    'nombre': 'Bodega Don Lucho',
    'celular': '987654321',
    'personas': [
      {
        'rol': 'dueno',
        'titular': true,
        'celular': '987654321',
        'version_app': 'entrega-47 (180)',
        'subio_en': '2026-10-12T20:00:00Z',
      },
    ],
    'invitaciones': [
      {'celular': '987000002', 'rol': 'ayudante', 'estado': 'vencida'},
    ],
    'registros': 12,
    'cobro': hasta == null
        ? {'estado': 'prueba', 'hasta': '2026-10-14', 'dias': 2, 'precio': 1490}
        : {'estado': 'pagado', 'hasta': hasta, 'dias': 30, 'plan': 'fundador'},
    'pagos': [
      if (hasta != null)
        {
          'id': 'pago-1',
          'plan': 'fundador',
          'monto_centimos': 1490,
          'desde': '2026-10-15',
          'hasta': hasta,
          'nota': 'op 123',
          'anulado_en': anulados.isEmpty ? null : '2026-10-12T21:00:00Z',
        },
    ],
    'respuestas': [
      {'respuesta': 'si', 'motivo': null, 'precio_centimos': 1490},
    ],
    'uso': {
      'dias_que_abrio': 5,
      'dias_que_anoto': 4,
      'ventas_anotadas': 6,
      'segundos_para_anotar': 8,
      'voz_con_duda': 1,
      'voz_corregida': 0,
      'fotos_ilegibles': 2,
      'avisos_respondidos': 3,
      'avisos_abiertos': 4,
      'arqueos_abiertos': 1,
      'informes_abiertos': 2,
      'ultima_apertura': '2026-10-12T15:00:00Z',
    },
  };

  /// El equipo (entrega 19): lo que responde «/equipo», las invitaciones
  /// para «Me invitaron» y lo que se invitó, quitó o aceptó.
  Map<String, Object?>? equipo;
  List<Map<String, Object?>> invitacionesRecibidas = [];
  String? errorAlInvitar;
  final invitados = <Map<String, Object?>>[];
  final quitados = <Object?>[];
  final aceptadas = <Object?>[];

  Future<http.Response> responder(http.Request pedido) async {
    final bytes = pedido.headers['Content-Encoding'] == 'gzip'
        ? gzip.decode(pedido.bodyBytes)
        : pedido.bodyBytes;
    final cuerpo = bytes.isEmpty
        ? const <String, Object?>{}
        : jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    final conLlave =
        pedido.headers['Authorization'] == 'Bearer llave-de-prueba' &&
        !sesionRevocada;
    switch (pedido.url.path) {
      case '/cuenta/codigo':
        codigosPedidos.add(cuerpo['celular']! as String);
        marcasPedidas.add(cuerpo['marcaApp']);
        return http.Response(jsonEncode({'canal': 'sms'}), estadoAlPedir);
      case '/cuenta/verificar' when cuerpo['modo'] == 'invitado':
        if (cuerpo['codigo'] != '123456') {
          return http.Response(jsonEncode({'error': 'codigo_incorrecto'}), 400);
        }
        if (invitacionesRecibidas.isEmpty) {
          return http.Response(jsonEncode({'error': 'sin_invitacion'}), 404);
        }
        return http.Response(
          jsonEncode({
            'llave': 'llave-de-prueba',
            'usuarioId': cuerpo['usuarioId'],
            'empresas': <String>[],
            'cuentaExistente': false,
            'invitaciones': invitacionesRecibidas,
          }),
          200,
        );
      case '/cuenta/aceptar':
        aceptadas.add(cuerpo['invitacion']);
        return cuerpo['consentimiento'] == true
            ? http.Response(jsonEncode({'rol': 'ayudante'}), 200)
            : http.Response(jsonEncode({'error': 'datos_invalidos'}), 400);
      case '/equipo':
        return http.Response(jsonEncode(equipo), equipo == null ? 403 : 200);
      case '/equipo/invitar':
        if (errorAlInvitar case final error?) {
          return http.Response(jsonEncode({'error': error}), 409);
        }
        invitados.add(cuerpo);
        return http.Response(jsonEncode({'id': 'nueva'}), 200);
      case '/equipo/quitar':
        quitados.add(cuerpo['membresia']);
        return http.Response(jsonEncode({'quitada': true}), 200);
      case '/cuenta/verificar':
        final entrar = cuerpo['modo'] == 'entrar';
        return switch (cuerpo['codigo']) {
          '123456' when entrar && cuentaParaEntrar == null => http.Response(
            jsonEncode({'error': 'sin_cuenta'}),
            404,
          ),
          '123456' => http.Response(
            jsonEncode({
              if (!cuentaExistente || entrar) 'llave': 'llave-de-prueba',
              'usuarioId': cuerpo['usuarioId'],
              'empresas': [
                if (cuentaExistente && !cuentaSinNegocio)
                  '0f0e0d0c-0000-4000-8000-0000000000e1',
              ],
              'cuentaExistente': cuentaExistente && !entrar,
              if (cuentaExistente && !entrar) 'pase': 'pase-de-prueba',
            }),
            200,
          ),
          '000000' => http.Response(
            jsonEncode({'error': 'codigo_vencido'}),
            400,
          ),
          _ => http.Response(jsonEncode({'error': 'codigo_incorrecto'}), 400),
        };
      case '/cuenta/con-pase':
        conPase.add(cuerpo['accion']! as String);
        return http.Response(
          jsonEncode({
            'llave': 'llave-de-prueba',
            'usuarioId': cuerpo['usuarioId'],
            'empresas': <String>[],
          }),
          200,
        );
      case '/cuenta/borrar-datos':
        if (!conLlave) {
          return http.Response(jsonEncode({'error': 'sin_sesion'}), 401);
        }
        borrados.add(cuerpo['confirmacion']);
        return http.Response(jsonEncode({'borradas': 1}), 200);
      case '/datos/subir':
        if (!conLlave) {
          return http.Response(jsonEncode({'error': 'sin_sesion'}), 401);
        }
        subidas.add(cuerpo);
        return http.Response(jsonEncode({'recibidos': <String, int>{}}), 200);
      case '/cobro/resumen':
        return http.Response(
          jsonEncode({
            'fundadores': {'usados': pagos.length, 'maximo': 50},
            'negocios': [fichaDeLucho()],
            'sin_abrir': [
              {
                ...fichaDeLucho(),
                'nombre': 'Pollería Rosa',
                'celular': '911222333',
                'ultima_apertura': null,
              },
            ],
            'revisar': [
              {
                'id': 'orden-9',
                'nombre': 'Bodega Don Lucho',
                'celular': '987654321',
                'plan': 'fundador',
                'monto_centimos': 1490,
                'motivo': 'monto',
                'mp_pago_id': '5005',
              },
            ],
          }),
          200,
        );
      // Soporte (entrega 47): el número de Lucho tiene su negocio; el
      // 987000099, ninguna cuenta.
      case '/soporte/buscar':
        return http.Response(
          jsonEncode(
            pedido.url.queryParameters['celular'] == '987654321'
                ? {
                    'tiene_cuenta': true,
                    'negocios': [
                      {
                        'empresa_id': 'empresa-lucho',
                        'nombre': 'Bodega Don Lucho',
                        'rol': 'dueno',
                        'titular': true,
                      },
                    ],
                  }
                : {'tiene_cuenta': false, 'negocios': []},
          ),
          200,
        );
      case '/soporte/dias-prueba':
        diasDados.add(cuerpo['dias']);
        return http.Response(jsonEncode(fichaDeLucho()), 200);
      case '/soporte/borrar':
        return cuerpo['confirmacion'] == 'Bodega Don Lucho'
            ? http.Response(jsonEncode({'borrado': true}), 200)
            : http.Response(jsonEncode({'error': 'sin_confirmacion'}), 400);
      case '/cobro/negocio':
        return pedido.url.queryParameters['celular'] == '987654321' ||
                pedido.url.queryParameters['empresa'] == 'empresa-lucho'
            ? http.Response(
                jsonEncode(
                  fichaDeLucho(hasta: pagos.isEmpty ? null : '2026-11-14'),
                ),
                200,
              )
            : http.Response(jsonEncode({'error': 'sin_negocio'}), 404);
      case '/cobro/anular':
        anulados.add(cuerpo['pago']);
        return http.Response(jsonEncode(fichaDeLucho()), 200);
      case '/cobro/pago':
        pagos.add(cuerpo);
        return http.Response(
          jsonEncode(fichaDeLucho(hasta: '2026-11-14')),
          200,
        );
      case '/cobro/mercadopago':
        ordenesPedidas++;
        ultimaOrden = cuerpo;
        final error = errorMercadoPago;
        return error != null
            ? http.Response(jsonEncode({'error': error}), 503)
            : http.Response(
                jsonEncode({
                  'orden': 'orden-1',
                  'enlace': 'https://mp.falso/pagar/orden-1',
                  'monto_centimos': 1490,
                }),
                200,
              );
      case '/cobro/mis-pagos':
        return http.Response(
          jsonEncode({
            'pagos': [
              {
                'id': 'p-2',
                'plan': 'fundador',
                'monto_centimos': 1490,
                'desde': '2026-12-26',
                'hasta': '2027-01-25',
                'pagado_en': '2026-11-06T15:00:00.000Z',
                'medio': 'yape',
                'anulado': false,
              },
              {
                'id': 'p-1',
                'plan': 'fundador',
                'monto_centimos': 1490,
                'desde': '2026-11-26',
                'hasta': '2026-12-25',
                'pagado_en': '2026-11-05T15:00:00.000Z',
                'medio': 'mercadopago',
                'operacion': '5001',
                'anulado': true,
              },
            ],
            'en_revision': [
              {'monto_centimos': 1490, 'desde_el': '2026-11-06T15:00:00.000Z'},
            ],
          }),
          200,
        );
      case '/cobro/orden/orden-1':
        consultasDeOrden++;
        return http.Response(jsonEncode(orden), 200);
      case '/cobro/respuesta':
        respuestasDePrecio.add(cuerpo);
        return http.Response(jsonEncode({'recibida': true}), 200);
      case '/errores' when pedido.method == 'GET':
        return http.Response(
          jsonEncode({
            'errores': [
              {
                'mensaje': 'Bad state: se rompió',
                'veces': 3,
                'negocios': 2,
                'personas': 2,
                'ultima': '2026-10-12T20:00:00Z',
                'pila': '#0 algo',
                'pantalla': '/inicio',
                'entrega': 'piloto-1',
                'armado': 120,
              },
            ],
          }),
          200,
        );
      case '/app/version':
        canalesPedidos.add(pedido.url.queryParameters['canal']);
        return http.Response(jsonEncode(version), 200);
      case '/equipo/salir':
        salidas++;
        return http.Response(jsonEncode({'salio': true}), 200);
      case '/datos/cambios':
        pedidosDeCambios++;
        // Entrega 37: el negocio se borró, o lo quitaron.
        if (sinAccesoAlNegocio case final motivo?) {
          return http.Response(jsonEncode({'error': motivo}), 403);
        }
        return http.Response(jsonEncode({'hasta': 0}), 200);
      case '/datos/bajar':
        if (cortarBajada) {
          cortarBajada = false;
          throw http.ClientException('Se cortó la señal');
        }
        return http.Response(jsonEncode({'datos': cuentaParaEntrar}), 200);
    }
    return http.Response('', 404);
  }
}

/// Lo que tiene en el servidor la cuenta de Don Lucho: S/ 1,000 al empezar
/// y una venta de S/ 350.
Map<String, Object?> _cuentaDeLucho() {
  const usuario = '0f0e0d0c-0000-4000-8000-000000000001';
  const empresa = '0f0e0d0c-0000-4000-8000-000000000002';
  const efectivo = '0f0e0d0c-0000-4000-8000-000000000003';
  const venta = '0f0e0d0c-0000-4000-8000-000000000004';
  const categoria = '0f0e0d0c-0000-4000-8000-000000000005';
  final dia = _ahora.toUtc().toIso8601String();
  return {
    'usuario': {'id': usuario, 'celular': '+51987654321'},
    'membresia': {
      'id': '0f0e0d0c-0000-4000-8000-000000000006',
      'empresa_id': empresa,
      'rol': 'dueno',
    },
    'empresa': {
      'id': empresa,
      'nombre': 'Bodega Don Lucho',
      'tipo_negocio': 'bodega',
      'modo': 'simple',
      'pais': 'PE',
      'moneda': 'PEN',
      'regimen': null,
      'hora_cierre_minutos': 1260,
      'identificacion_fiscal': null,
      'creado_en': dia,
    },
    'cuentas': [
      {
        'id': efectivo,
        'tipo': 'efectivo',
        'nombre': 'Efectivo',
        'orden': 0,
        'saldo_inicial_centimos': 100000,
        'fecha_saldo_inicial': _ahora
            .subtract(const Duration(hours: 1))
            .toUtc()
            .toIso8601String(),
      },
    ],
    // Las categorías de hoy, para que lo que baja no cambie nada.
    'categorias': [
      for (final (i, (nombre, tipo)) in [
        for (final n in categoriasComunesIngreso) (n, 'ingreso'),
        for (final n in categoriasComunesEgreso) (n, 'egreso'),
      ].indexed)
        {
          'id': i == 0
              ? categoria
              : '0f0e0d0c-0000-4000-8000-${(100 + i).toString().padLeft(12, '0')}',
          'nombre': nombre,
          'tipo_movimiento': tipo,
          'orden': i,
          'activa': true,
        },
    ],
    'movimientos': [
      {
        'id': venta,
        'tipo': 'ingreso',
        'cuenta_id': efectivo,
        'monto_centimos': 35000,
        'fecha_movimiento': dia,
        'fecha_comprobante': null,
        'estado_pago': 'pagado',
        'monto_pagado_centimos': 35000,
        'fecha_vencimiento': null,
        'fecha_pago': dia,
        'categoria_id': categoria,
        'contraparte_id': null,
        'comprobante_id': null,
        'nivel_confianza': 'd',
        'fuente': 'voz',
        'autor_id': usuario,
        'nota': null,
        'estado': 'vigente',
        'reemplaza_a': null,
        'creado_en': dia,
      },
    ],
    'dias_cerrados': [
      {'id': '0f0e0d0c-0000-4000-8000-000000000007', 'dia': '2026-10-11'},
    ],
    'bitacora': [
      {
        'id': '0f0e0d0c-0000-4000-8000-000000000008',
        'autor_id': usuario,
        'entidad': 'movimiento',
        'entidad_id': venta,
        'accion': 'crear',
        'valor_anterior': null,
        'valor_nuevo': {'montoCentimos': 35000},
        'fecha': dia,
      },
    ],
  };
}

/// Los videos de ayuda (entrega 14.6): sus enlaces y lo que se abrió.
var _enlaces = <VideoTutoria, String>{};
final _abiertos = <String>[];
var _abreVideos = true;

class _AbridorFalso implements AbridorDeEnlaces {
  @override
  Future<bool> abrir(String enlace) async {
    if (!_abreVideos) return false;
    _abiertos.add(enlace);
    return true;
  }
}

/// El SMS del código (entrega 14.7): la marca de la app y los SMS que
/// llegan. Sin marca, el teléfono no puede leerlos.
String? _marcaSms;
var _sms = StreamController<String>.broadcast();
var _esperandoSms = 0;

class _LectorSmsFalso implements LectorCodigoSms {
  @override
  Future<String?> marca() async => _marcaSms;

  @override
  Future<void> esperar() async => _esperandoSms++;

  @override
  Stream<String> get codigos => _sms.stream;

  @override
  Future<void> dejarDeEsperar() async {}
}

var _servidor = _ServidorFalso();
var _llavero = _LlaveroFalso();

class _LlaveroFalso implements Llavero {
  String? _llave;

  @override
  Future<String?> leer() async => _llave;

  @override
  Future<void> guardar(String llave) async => _llave = llave;
}

/// Lo que devuelve la cámara en la próxima foto.
ResultadoCamara _camara = const FotoTomada('/no/existe.jpg');

/// Lo que responde el lector de fotos, en orden; vacía, el de la Demo.
final _lecturas = <ResultadoLectura>[];

class _LectorFalso implements LectorFoto {
  _LectorFalso(this._deEjemplo);
  final LectorFoto _deEjemplo;

  @override
  Future<ResultadoLectura> leer(String rutaImagen) async =>
      _lecturas.isEmpty ? _deEjemplo.leer(rutaImagen) : _lecturas.removeAt(0);
}

/// La versión instalada (entrega 26.3): en las pruebas, desconocida.
var _versionInstalada = const VersionInstalada(
  entrega: '',
  armado: 0,
  commit: '',
  esArm64: true,
);

/// La huella del teléfono (entrega 16.3).
var _hayBloqueo = true;
var _pasaLaHuella = true;
var _huellasPedidas = 0;

class _CerraduraFalsa implements Cerradura {
  @override
  Future<bool> puedeUsarse() async => _hayBloqueo;

  @override
  Future<bool> verificar(String motivo) async {
    _huellasPedidas++;
    return _pasaLaHuella;
  }
}

class _CamaraFalsa implements Camara {
  @override
  Future<ResultadoCamara> tomarFoto() async => _camara;
}

class _VozFalsa implements ReconocedorVoz {
  @override
  Future<DisponibilidadVoz> preparar() async => _vozDisponible;

  @override
  Stream<EventoVoz> escuchar() => Stream.fromIterable([
    VozParcial(_loQueDice.first.texto),
    VozFinal(_loQueDice),
  ]);

  @override
  Future<void> detener() async {}
}

/// Abre la app con una base en memoria. Con `listo`, el camino del primer
/// día ya está hecho (venta de S/ 350 en efectivo y saldo de S/ 1,000).
Future<BaseLocal> abrirApp(
  WidgetTester tester, {
  bool listo = false,
  bool permisoPreguntado = true,
  bool conHuella = false,
  bool pasaLaHuella = true,
  // Las pruebas abren la app como Jhony, que sí abre el ajuste oculto
  // (entrega 26.2).
  bool admin = true,
  Rol? verComoAlAbrir,
  VersionInstalada versionInstalada = const VersionInstalada(
    entrega: '',
    armado: 0,
    commit: '',
    esArm64: true,
  ),
  Map<String, Object?>? versionDelServidor,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  _versionInstalada = versionInstalada;
  _hayBloqueo = true;
  _pasaLaHuella = pasaLaHuella;
  _huellasPedidas = 0;
  _loQueDice = [const AlternativaVoz('hola')];
  _vozDisponible = DisponibilidadVoz.disponible;
  _camara = const FotoTomada('/no/existe.jpg');
  _lecturas.clear();
  _conSenal = true;
  _loQueDijo.clear();
  _hayVoz = true;
  _programado = [];
  _avisosDePrueba = 0;
  _daPermiso = true;
  _abrirDesdeAviso = null;
  _servidor = _ServidorFalso();
  if (versionDelServidor != null) _servidor.version = versionDelServidor;
  _marcaSms = null;
  _sms = StreamController<String>.broadcast();
  _esperandoSms = 0;
  _enlaces = {};
  _abiertos.clear();
  _abreVideos = true;
  _ahora = _ahoraInicial;
  _llavero = _LlaveroFalso();
  // Tamaño del lienzo de los mockups: 390 × 844.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // En pruebas de pantalla, las consultas que se observan se cierran sin
  // temporizadores pendientes.
  final base = BaseLocal(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  if (permisoPreguntado) {
    await tester.runAsync(
      () => base
          .into(base.ajustes)
          .insert(
            AjustesCompanion.insert(clave: 'permiso_avisos', valor: 'si'),
          ),
    );
  }
  if (listo) {
    await tester.runAsync(() async {
      final repo = RepositorioPrimerDiaLocal(base, ahora: () => _ahora);
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
    });
  }

  await tester.runAsync(() async {
    final acceso = AccesoLocal(base, () => _ahora);
    if (admin) {
      await acceso.guardarAjuste(
        AccesoLocal.claveCobro,
        jsonEncode({'estado': 'sin_cobro', 'admin': true}),
      );
    }
    if (verComoAlAbrir != null) {
      await acceso.guardarAjuste(AccesoLocal.claveVerComo, verComoAlAbrir.name);
    }
  });
  if (conHuella) {
    await tester.runAsync(
      () => AccesoLocal(
        base,
        () => _ahora,
      ).guardarAjuste(AccesoLocal.clavePedirHuella, 'si'),
    );
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        baseLocalProvider.overrideWithValue(base),
        relojProvider.overrideWithValue(() => _ahora),
        conexionTelefonoProvider.overrideWithValue(_SenalFalsa()),
        locutorProvider.overrideWithValue(_LocutorFalso()),
        compartidorProvider.overrideWithValue(_CompartidorFalso()),
        abridorProvider.overrideWithValue(_AbridorFalso()),
        lectorCodigoSmsProvider.overrideWithValue(_LectorSmsFalso()),
        enlacesDeVideosProvider.overrideWith((ref) => _enlaces),
        notificadorProvider.overrideWithValue(_NotificadorFalso()),
        servicioCuentaProvider.overrideWith(
          (ref) => ServicioCuentaRemoto(
            base,
            llavero: _llavero,
            lectorSms: ref.watch(lectorCodigoSmsProvider),
            cliente: MockClient(_servidor.responder),
            ahora: () => _ahora,
            hayConexion: ref.watch(conexionProvider).hayConexion,
          ),
        ),
        reconocedorVozProvider.overrideWith((ref) => _VozFalsa()),
        camaraProvider.overrideWithValue(_CamaraFalsa()),
        cerraduraProvider.overrideWithValue(_CerraduraFalsa()),
        versionInstaladaProvider.overrideWith((ref) => _versionInstalada),
        lectorFotoProvider.overrideWith(
          (ref) => _LectorFalso(
            LectorFotoSimulado(
              ahora: () => _ahora,
              espera: Duration.zero,
              forzarIlegible: () =>
                  ref.read(forzarIlegibleProvider.notifier).usar(),
            ),
          ),
        ),
      ],
      child: const MocaApp(),
    ),
  );
  await esperar(tester);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await base.close();
  });
  return base;
}

/// Deja que la base responda y que la interfaz termine de moverse.
Future<void> esperar(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}

Future<void> tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await esperar(tester);
}

/// Mantiene presionado el isotipo de la pestaña Moca hasta abrir el ajuste
/// oculto.
Future<void> abrirAjusteOculto(WidgetTester tester) async {
  await tocar(tester, find.text(Textos.pestanaMoca).last);
  final gesto = await tester.startGesture(
    tester.getCenter(find.byKey(PantallaMoca.claveIsotipo)),
  );
  await tester.pump(PantallaMoca.esperaAjusteOculto);
  await gesto.up();
  await esperar(tester);
}

/// Una opción del ajuste oculto: la lista es larga y se arma al verse.
Future<void> tocarEnAjuste(WidgetTester tester, String opcion) async {
  await tester.scrollUntilVisible(
    find.text(opcion),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tocar(tester, find.text(opcion));
}

/// La explicación de «Tienes hoy» está detrás del ⓘ (mejora 01): la abre,
/// comprueba que diga [nota] y la cierra.
Future<void> verNotaDeTienesHoy(WidgetTester tester, String nota) async {
  await tocar(tester, find.byTooltip(Textos.queEsEstaCifra));
  expect(find.text(nota), findsOneWidget);
  await tocar(tester, find.text(Textos.entendido).last);
}

/// «Ajustes», desde el ⚙ del encabezado del Inicio (mejora 01).
Future<void> abrirAjustes(WidgetTester tester) async {
  await tocar(tester, find.text(Textos.pestanaInicio).last);
  await tocar(tester, find.byTooltip(Textos.ajustes));
}

/// Desde la Bienvenida, la primera venta escrita en lugar de dicha.
Future<void> abrirVentaEscrita(WidgetTester tester) async {
  await tocar(tester, find.text(Textos.anotarPrimeraVenta));
  await tocar(tester, find.text(Textos.prefieroEscribirlo));
}

void main() {
  group('Camino del primer día', () {
    testWidgets('Un teléfono nuevo abre en la Bienvenida', (tester) async {
      await abrirApp(tester);
      expect(find.text(Textos.anotarPrimeraVenta), findsOneWidget);
      expect(find.byType(BarraInferior), findsNothing);
    });

    testWidgets('Recorrido completo: venta, celular, código, alta, primer '
        'día', (tester) async {
      final base = await abrirApp(tester);

      // S00 → S07 escrita
      await abrirVentaEscrita(tester);
      expect(find.text(Textos.cuantoVendisteHoy), findsOneWidget);
      final guardar = find.widgetWithText(FilledButton, Textos.guardar);
      expect(tester.widget<FilledButton>(guardar).onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(0), '350');
      await tester.enterText(find.byType(TextField).at(1), '120');
      await tester.pump();
      expect(find.text('S/ 470'), findsOneWidget);
      await tocar(tester, guardar);

      // S01
      expect(find.text(Textos.primeraVentaAnotada), findsOneWidget);
      expect(find.text(Textos.hoyEntraron('S/ 470')), findsOneWidget);
      final enviar = find.widgetWithText(FilledButton, Textos.enviarmeCodigo);
      await tester.enterText(find.byType(TextField), '8');
      await tester.pump();
      expect(find.text(Textos.celularInvalido), findsOneWidget);
      await tester.enterText(find.byType(TextField), '987654321');
      await tester.pump();
      expect(find.text(Textos.celularInvalido), findsNothing);
      expect(find.text('987 654 321'), findsOneWidget);
      await tocar(tester, enviar);

      // Código, enviado de verdad por el servidor
      expect(_servidor.codigosPedidos, ['987654321']);
      expect(find.text(Textos.codigoEnviadoA('987 654 321')), findsOneWidget);
      await tester.enterText(find.byType(TextField), '111111');
      await esperar(tester);
      expect(find.text(Textos.codigoIncorrecto), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await esperar(tester);
      // Al verificar, sube lo anotado: la venta de S/ 470.
      expect(_servidor.subidas, hasLength(1));
      expect([
        for (final m in _servidor.subidas.single['movimientos']! as List)
          (m as Map)['monto_centimos'],
      ], unorderedEquals([35000, 12000]));

      // S02
      expect(find.text(Textos.cuentaleDeTuNegocio), findsOneWidget);
      final listo = find.widgetWithText(FilledButton, Textos.listoEmpezar);
      expect(tester.widget<FilledButton>(listo).onPressed, isNull);
      await tester.enterText(find.byType(TextField).at(0), 'Bodega Don Lucho');
      await tocar(
        tester,
        find.text(Textos.nombreTipoNegocio(TipoNegocio.bodega)),
      );
      await tester.enterText(find.byType(TextField).at(1), '1200');
      await tester.pump();
      expect(find.text('1,200'), findsOneWidget);
      await tocar(tester, listo);

      // S03
      expect(find.text(Textos.tuPrimerDia), findsOneWidget);
      expect(find.text('Bodega Don Lucho'), findsOneWidget);
      expect(find.text('S/ 1,670'), findsOneWidget);
      expect(find.text(Textos.mocaYaAnotaste), findsOneWidget);
      expect(find.text(Textos.pasoVentaCincoDias(1)), findsOneWidget);
      expect(find.byType(BarraInferior), findsOneWidget);

      final usuario = await tester.runAsync(
        () => base.select(base.usuarios).getSingle(),
      );
      expect(usuario!.celular, '987654321');
    });

    testWidgets('«Ahora no» y «lo pongo después» dejan el saldo pendiente, y '
        'el paso 1 lo pide', (tester) async {
      await abrirApp(tester);
      await abrirVentaEscrita(tester);
      await tester.enterText(find.byType(TextField).at(0), '350');
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tocar(tester, find.text(Textos.ahoraNo));

      await tester.enterText(find.byType(TextField).at(0), 'Taller Rojas');
      // La lista de tipos es larga (entrega 48): se cierra el teclado, que
      // si no vuelve a subir la pantalla hasta el nombre, y se baja.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text(Textos.nombreTipoNegocio(TipoNegocio.otro)),
        200,
        scrollable: find
            .ancestor(
              of: find.text(Textos.queTipoDeNegocio),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tocar(
        tester,
        find.text(Textos.nombreTipoNegocio(TipoNegocio.servicios)),
      );
      await tocar(tester, find.text(Textos.noSeCuantoTengo));

      await verNotaDeTienesHoy(tester, Textos.notaSaldoPendiente);
      // El total y el desglose de Efectivo (entrega 14.9).
      expect(find.text('S/ 350'), findsNWidgets(2));

      await tocar(tester, find.text(Textos.pasoDecirPlata));
      expect(find.text(Textos.cuantoTeniasAlEmpezar), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), '500');
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.guardarSaldo),
      );
      await verNotaDeTienesHoy(tester, Textos.notaSaldoMasVenta);
      // El total y el desglose de Efectivo (entrega 14.9).
      expect(find.text('S/ 850'), findsNWidgets(2));
    });

    testWidgets('Al volver a abrir la app, sigue en el paso pendiente', (
      tester,
    ) async {
      final base = await abrirApp(tester);
      await abrirVentaEscrita(tester);
      await tester.enterText(find.byType(TextField).at(0), '350');
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(find.text(Textos.guardaTuAvance), findsOneWidget);

      // Se cierra la app y se vuelve a abrir con la misma base.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            baseLocalProvider.overrideWithValue(base),
            relojProvider.overrideWithValue(() => _ahora),
            conexionTelefonoProvider.overrideWithValue(_SenalFalsa()),
            notificadorProvider.overrideWithValue(_NotificadorFalso()),
            servicioCuentaProvider.overrideWith(
              (ref) => ServicioCuentaRemoto(
                base,
                llavero: _llavero,
                cliente: MockClient(_servidor.responder),
                ahora: () => _ahora,
                hayConexion: ref.watch(conexionProvider).hayConexion,
              ),
            ),
          ],
          child: const MocaApp(),
        ),
      );
      await esperar(tester);
      expect(find.text(Textos.guardaTuAvance), findsOneWidget);
      final movimientos = await tester.runAsync(
        () => base.select(base.movimientos).get(),
      );
      expect(movimientos, hasLength(1));
    });

    testWidgets('«Ya tengo cuenta» con un número sin cuenta lleva a la '
        'primera venta', (tester) async {
      await abrirApp(tester);
      await tocar(tester, find.text(Textos.yaTengoCuenta));
      expect(find.text(Textos.entraATuCuentaDetalle), findsOneWidget);
      await tester.enterText(find.byType(TextField), '987654321');
      await tester.pump();
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.enviarmeCodigo),
      );
      await tester.enterText(find.byType(TextField), '123456');
      await esperar(tester);
      expect(find.text(Textos.numeroSinCuenta), findsOneWidget);
      await tocar(tester, find.text(Textos.anotarMiPrimeraVenta));
      expect(find.text(Textos.microfonoExplicacion), findsOneWidget);
    });
  });

  group('Con el primer día hecho', () {
    testWidgets('Abre en el Inicio con la barra inferior completa', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      for (final etiqueta in [
        Textos.pestanaInicio,
        Textos.pestanaHistorial,
        Textos.pestanaInformes,
        Textos.pestanaMoca,
      ]) {
        expect(
          find.descendant(
            of: find.byType(BarraInferior),
            matching: find.text(etiqueta),
          ),
          findsOneWidget,
        );
      }
      // El total y el desglose de Efectivo (entrega 14.9).
      expect(find.text('S/ 1,350'), findsNWidgets(2));
      expect(find.bySemanticsLabel(Textos.registrar), findsOneWidget);
    });

    testWidgets('La barra inferior ocupa solo su alto', (tester) async {
      await abrirApp(tester, listo: true);
      // Mockup: 8 + 60 (botón central) + 16 de relleno, más el borde.
      final alto = tester.getSize(find.byType(BarraInferior)).height;
      expect(alto, inInclusiveRange(84, 90));
    });

    testWidgets('Cada pestaña dice en qué entrega llega', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaHistorial));
      expect(find.text(Textos.filtroTodo), findsOneWidget);
      await tocar(tester, find.text(Textos.pestanaInformes));
      expect(find.text(Textos.compartir), findsOneWidget);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(Textos.eslogan), findsOneWidget);
    });

    testWidgets('El botón central abre Registrar; voz, foto y QR dicen en qué '
        'entrega llegan', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      expect(find.text(Textos.diloOMuestralo), findsOneWidget);
      // Sin cuenta, la foto dice cuántas pruebas quedan (entrega 14.2).
      expect(find.text(Textos.fotosDePruebaQuedan(3)), findsOneWidget);
      expect(find.text(Textos.leerQrDetalle), findsOneWidget);
      await tocar(tester, find.text(Textos.escribirlo));
      expect(find.text(Textos.queFue), findsOneWidget);
    });

    testWidgets('Mejora 01: las pantallas nuevas no se desbordan con letra '
        'grande', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      await tester.enterText(find.byType(TextField).first, '80');
      await tocar(tester, find.text(Textos.salio));
      expect(tester.takeException(), isNull, reason: 'Escribirlo');
      await tocar(tester, find.byType(BotonVolver).first);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(tester.takeException(), isNull, reason: 'Asistente');
      await tocar(tester, find.text(Textos.pestanaInicio).last);
      await tocar(tester, find.byTooltip(Textos.ajustes));
      expect(tester.takeException(), isNull, reason: 'Ajustes');
      await tocar(tester, find.byType(BotonVolver).first);
      await tocar(tester, find.text(Textos.pestanaInformes));
      await tocar(tester, find.text(Textos.verAnio));
      expect(tester.takeException(), isNull, reason: 'Año');
    });

    testWidgets('Mejora 01: el + abre la hoja con atajos; «Un gasto» abre '
        'Escribirlo con «Salió» y «Venta del día», la venta', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text(Textos.atajos), findsOneWidget);
      await tocar(tester, find.text(Textos.atajoUnGasto));
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(Textos.yaLoPagaste), findsOneWidget);
      await tocar(tester, find.byType(BotonVolver).first);

      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.atajoVentaDelDia));
      expect(find.text(Textos.cuantoVendisteHoy), findsOneWidget);
      await tocar(tester, find.byType(BotonVolver).first);

      // «Cancelar» la cierra sin abrir nada.
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.cancelar));
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(Textos.tienesHoy), findsOneWidget);
    });

    testWidgets('Mejora 01: el Inicio muestra lo pendiente con nombres y, '
        'con la venta anotada, «Escuchar mi semana»', (tester) async {
      await abrirApp(tester, listo: true);
      // Sin nada pendiente, no hay bloque.
      expect(find.textContaining('Te deben ·'), findsNothing);
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      await tocar(tester, find.text(Textos.entro).first);
      await tester.enterText(find.byType(TextField).first, '80');
      await tester.pump();
      await tocar(tester, find.text(Textos.todaviaMeDebe));
      await tester.enterText(
        find.widgetWithText(TextField, Textos.quienTeDebeEjemplo),
        'Doña Rosa',
      );
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.pump(const Duration(seconds: 5));
      await esperar(tester);

      expect(find.text(Textos.teDebenCuantos(1)), findsOneWidget);
      expect(find.text('Doña Rosa'), findsOneWidget);
      expect(find.text(Textos.escucharMiSemana), findsOneWidget);
      // Entrega 51: cuánto de lo vendido hoy se fió, y el ⓘ no cuenta lo
      // fiado como plata en la mano.
      expect(
        find.text(
          '${Textos.vendisteHoy('S/\u00A0430')} · '
          '${Textos.alFiado('S/\u00A080')}',
        ),
        findsOneWidget,
      );
      await verNotaDeTienesHoy(tester, Textos.notaConMovimientos);
      await tocar(tester, find.text(Textos.teDebenCuantos(1)));
      expect(find.text(Textos.loQueTeDebenTitulo), findsWidgets);
      await tocar(tester, find.byType(BotonVolver).first);

      await tocar(tester, find.text(Textos.escucharMiSemana));
      expect(find.text(Textos.avisos), findsWidgets);
    });

    testWidgets('Mejora 01: Ajustes desde el ⚙ del Inicio; la campana lleva '
        'a los avisos del Asistente', (tester) async {
      await abrirApp(tester, listo: true);
      expect(find.text(Textos.pestanaMoca), findsWidgets);
      await tocar(tester, find.byTooltip(Textos.avisos));
      expect(find.text(Textos.avisos), findsWidgets);
      expect(find.text(Textos.ajustes), findsNothing);
      await tocar(tester, find.text(Textos.pestanaInicio).last);
      await tocar(tester, find.byTooltip(Textos.ajustes));
      expect(find.text(Textos.ajustes), findsWidgets);
    });

    Future<void> abrirEscribir(WidgetTester tester) async {
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
    }

    FilledButton botonGuardar(WidgetTester tester) =>
        tester.widget(find.widgetWithText(FilledButton, Textos.guardar));

    testWidgets('Mejora 01: «Escribirlo» dice qué falta para guardar y '
        'muestra las categorías con nombre corto', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirEscribir(tester);
      expect(
        find.text(Textos.falta([Textos.faltaElMonto, Textos.faltaQueFue])),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField).first, '80');
      await tester.pump();
      expect(find.text(Textos.falta([Textos.faltaQueFue])), findsOneWidget);
      await tocar(tester, find.text(Textos.salio));
      expect(find.text(Textos.falta([Textos.faltaEnQueFue])), findsOneWidget);
      await tocar(tester, find.text(Textos.verMas));
      expect(find.text('Servicios'), findsOneWidget);
      expect(
        find.text('Servicios (luz, agua, internet, teléfono)'),
        findsNothing,
      );
      await tocar(tester, find.text('Servicios'));
      expect(find.textContaining('Falta:'), findsNothing);
      expect(botonGuardar(tester).onPressed, isNotNull);
    });

    testWidgets('«Escribirlo» guarda un gasto, avisa cuánto tienes y se '
        'puede deshacer', (tester) async {
      final base = await abrirApp(tester, listo: true);
      await abrirEscribir(tester);

      await tocar(tester, find.text(Textos.salio));
      await tester.enterText(find.byType(TextField).first, '80');
      await tester.pump();
      // Un gasto necesita categoría.
      expect(botonGuardar(tester).onPressed, isNull);
      await tocar(tester, find.text('Otros'));
      expect(botonGuardar(tester).onPressed, isNotNull);
      await tester.enterText(find.byType(TextField).last, 'bolsas');
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));

      expect(find.text(Textos.guardadoAhoraTienes('S/ 1,270')), findsOneWidget);
      // El total y el desglose de Efectivo (entrega 14.9).
      expect(find.text('S/ 1,270'), findsNWidgets(2));

      // «Tienes hoy» ya no es solo saldo más venta.
      await verNotaDeTienesHoy(tester, Textos.notaConMovimientos);

      await tocar(tester, find.text(Textos.deshacer));
      expect(find.text(Textos.seDeshizo), findsOneWidget);
      // El total y el desglose de Efectivo (entrega 14.9).
      expect(find.text('S/ 1,350'), findsNWidgets(2));
      final anulados = await tester.runAsync(
        () => (base.select(
          base.movimientos,
        )..where((m) => m.estado.equalsValue(EstadoRegistro.anulado))).get(),
      );
      expect(anulados, hasLength(1));
    });

    testWidgets('Entrega 41: «Todavía lo debo» al escribir una compra', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await abrirEscribir(tester);
      await tocar(tester, find.text(Textos.salio));
      await tester.enterText(find.byType(TextField).first, '80');
      await tester.pump();
      // Viene marcado «Sí, pagado»: se elige de dónde salió.
      expect(find.text(Textos.yaLoPagaste), findsOneWidget);
      expect(find.text(Textos.deDondeSalio), findsOneWidget);
      await tocar(tester, find.text(Textos.todaviaLoDebo));
      expect(find.text(Textos.deDondeSalio), findsNothing);
      expect(find.text(Textos.cuentaAlPagar), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, Textos.aQuienLeDebesEjemplo),
        'Distribuidora Rosita',
      );
      await tocar(tester, find.text('Otros'));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      // No baja la plata ni pregunta por el negativo.
      expect(
        find.text(Textos.guardadoAhoraTienes(formatearSoles(135000))),
        findsOneWidget,
      );
      final debe = await tester.runAsync(
        () =>
            (base.select(
                  base.movimientos,
                )..where((m) => m.estadoPago.equalsValue(EstadoPago.pendiente)))
                .getSingle(),
      );
      expect(debe!.montoCentimos, 8000);
      expect(debe.contraparteId, isNotNull);
    });

    testWidgets('Entrega 42: vender a crédito y cobrarlo', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirEscribir(tester);
      await tocar(tester, find.text(Textos.entro).first);
      await tester.enterText(find.byType(TextField).first, '200');
      await tester.pump();
      expect(find.text(Textos.yaTePagaron), findsOneWidget);
      await tocar(tester, find.text(Textos.todaviaMeDebe));
      expect(find.text(Textos.aDondeEntro), findsNothing);
      expect(find.text(Textos.cuentaAlCobrar), findsOneWidget);
      // Sin nombre no se guarda.
      expect(botonGuardar(tester).onPressed, isNull);
      await tester.enterText(
        find.widgetWithText(TextField, Textos.quienTeDebeEjemplo),
        'Doña Rosa',
      );
      await tester.pump();
      expect(botonGuardar(tester).onPressed, isNotNull);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      // No sube la plata.
      expect(
        find.text(Textos.guardadoAhoraTienes(formatearSoles(135000))),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await esperar(tester);
      await tocar(tester, find.text(Textos.pestanaInformes));
      await tester.scrollUntilVisible(
        find.text(Textos.loQueTeDebenTitulo),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(Textos.todoLoQueTeDeben), findsOneWidget);
      await tocar(tester, find.text(Textos.loQueTeDebenTitulo));
      expect(
        find.text(Textos.teDebenTotal(formatearSoles(20000), 1)),
        findsOneWidget,
      );
      expect(find.textContaining('Doña Rosa'), findsWidgets);
      await tocar(tester, find.byType(FilaMovimiento).first);
      expect(find.text(Textos.todaviaTeDebe), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.yaMePago));
      expect(find.text(Textos.cuandoTePago), findsOneWidget);
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.yaMePago).last,
      );
      expect(
        find.text(
          Textos.cobradoAhoraTienes(
            formatearSoles(155000),
            Textos.nombreCuenta(TipoCuenta.efectivo),
          ),
        ),
        findsOneWidget,
      );
      // Entrega 44.2: el cobro se deshace y vuelve a deberse.
      await tester.pump(const Duration(seconds: 5));
      await esperar(tester);
      await tocar(tester, find.text(Textos.deshacerElCobro));
      expect(
        find.text(
          Textos.preguntaDeshacerCobro(
            formatearSolesComprobante(20000),
            Textos.nombreCuenta(TipoCuenta.efectivo),
          ),
        ),
        findsOneWidget,
      );
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.deshacerElCobro),
      );
      expect(find.text(Textos.cobroDeshecho), findsOneWidget);
      expect(find.text(Textos.todaviaTeDebe), findsOneWidget);
      expect(find.text(Textos.deshicisteCobro), findsOneWidget);
    });

    testWidgets('Entrega 44: cobrar una venta a crédito en partes', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirEscribir(tester);
      await tocar(tester, find.text(Textos.entro).first);
      await tester.enterText(find.byType(TextField).first, '200');
      await tester.pump();
      await tocar(tester, find.text(Textos.todaviaMeDebe));
      await tester.enterText(
        find.widgetWithText(TextField, Textos.quienTeDebeEjemplo),
        'Doña Rosa',
      );
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.pump(const Duration(seconds: 5));
      await esperar(tester);
      await tocar(tester, find.text(Textos.pestanaInformes));
      await tester.scrollUntilVisible(
        find.text(Textos.loQueTeDebenTitulo),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.loQueTeDebenTitulo));
      // Entrega 45: recordarle por WhatsApp, sin su número.
      await tocar(tester, find.text(Textos.recordarPorWhatsApp));
      expect(_abiertos.single, startsWith('https://wa.me/?text='));
      expect(
        Uri.parse(_abiertos.single).queryParameters['text'],
        contains('Hola, Doña Rosa. Le escribimos de Bodega Don Lucho'),
      );
      await tocar(tester, find.byType(FilaMovimiento).first);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.yaMePago));
      expect(
        find.text(Textos.todoElMonto(formatearSolesComprobante(20000))),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.unaParte));
      // Todo no es una parte.
      await tester.enterText(find.widgetWithText(TextField, '').last, '200');
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.yaMePago).last,
      );
      expect(
        find.text(Textos.parteMenorQue(formatearSolesComprobante(20000))),
        findsOneWidget,
      );
      await tester.enterText(find.widgetWithText(TextField, '200'), '80');
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.yaMePago).last,
      );
      expect(
        find.text(
          Textos.cobradoParte(
            formatearSolesComprobante(8000),
            'Doña Rosa',
            formatearSolesComprobante(12000),
          ),
        ),
        findsOneWidget,
      );
      // La deuda queda con lo que falta y sus partes.
      expect(find.text(Textos.pagosEnPartes), findsOneWidget);
      expect(find.text(Textos.faltaPagar('')), findsOneWidget);
      // Con partes no se deshace: lo explica.
      await tester.pump(const Duration(seconds: 5));
      await esperar(tester);
      await tocar(tester, find.text(Textos.deshacerRegistro));
      expect(
        find.text(Textos.traba(TrabaDelRegistro.tienePartes)),
        findsOneWidget,
      );
    });

    testWidgets('Moca pregunta antes de dejar una cuenta en negativo', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirEscribir(tester);
      await tocar(tester, find.text(Textos.salio));
      await tester.enterText(find.byType(TextField).first, '80');
      await tocar(tester, find.text(Textos.yape));
      await tocar(tester, find.text('Otros'));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));

      expect(
        find.text(Textos.quedariaNegativo(Textos.yape, '−S/ 80')),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.revisar));
      expect(find.text(Textos.queFue), findsOneWidget);

      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tocar(tester, find.text(Textos.guardarIgual));
      expect(find.text(Textos.guardadoAhoraTienes('S/ 1,270')), findsOneWidget);
    });

    testWidgets('El retiro para mí no pide categoría', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirEscribir(tester);
      await tocar(tester, find.text(Textos.retiroParaMi));
      expect(find.text(Textos.retiroDetalle), findsOneWidget);
      expect(find.text(Textos.enQue), findsNothing);
      await tester.enterText(find.byType(TextField).first, '100');
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(find.text(Textos.guardadoAhoraTienes('S/ 1,250')), findsOneWidget);
    });

    testWidgets('«Un gasto» del + abre «Salió» elegido (mejora 01: el Primer '
        'día ya no repite el +)', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.atajoUnGasto));
      expect(find.text(Textos.enQue), findsOneWidget);
      expect(find.text('Mercadería'), findsOneWidget);
    });

    testWidgets('Un toque corto en el isotipo no abre el ajuste oculto', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      final gesto = await tester.startGesture(
        tester.getCenter(find.byKey(PantallaMoca.claveIsotipo)),
      );
      await tester.pump(const Duration(seconds: 1));
      await gesto.up();
      await esperar(tester);
      expect(find.text(Textos.tituloOperador), findsNothing);
    });

    testWidgets('«Borrar todo» pide confirmación y vacía el teléfono', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      expect(find.text(Textos.tituloOperador), findsOneWidget);
      expect(find.textContaining('registros guardados'), findsOneWidget);

      await tocarEnAjuste(tester, Textos.borrarTodo);
      await tocar(tester, find.text(Textos.cancelar));
      // La lista se desplazó: vuelve arriba, donde está el conteo.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await esperar(tester);
      expect(
        find.textContaining('registros guardados', skipOffstage: false),
        findsOneWidget,
      );

      await tocar(tester, find.text(Textos.borrarTodo));
      await tocar(tester, find.text(Textos.borrarTodoBoton));
      // Sin datos no hay negocio: la app vuelve a la Bienvenida.
      expect(find.text(Textos.seBorroTodo), findsOneWidget);
      expect(find.text(Textos.anotarPrimeraVenta), findsOneWidget);
    });

    testWidgets('«Empezar en Primer día» vuelve a la Bienvenida', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.empezarPrimerDia));
      await tocar(tester, find.text(Textos.empezarPrimerDiaBoton));
      expect(find.text(Textos.anotarPrimeraVenta), findsOneWidget);
    });

    testWidgets('Después de la primera semana se ve el Inicio completo; la '
        'venta de hoy se suma', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocarEnAjuste(tester, Textos.saltarPrimeraSemana);
      expect(find.text(Textos.primeraSemanaSaltada), findsOneWidget);
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));

      expect(find.text(Textos.tuPrimerDia), findsNothing);
      // Toda la plata está en efectivo: el total y Efectivo coinciden.
      expect(find.text('S/\u00A01,350'), findsNWidgets(2));
      expect(find.text(Textos.efectivo), findsOneWidget);
      // «Esta semana», cada monto con su signo (mejora 01).
      expect(find.text(Textos.estaSemana), findsOneWidget);
      expect(find.text('+\u00A0S/\u00A0350'), findsOneWidget);
      expect(find.text(Textos.mocaYaAnotasteHoy), findsOneWidget);

      // El ojo oculta los montos.
      await tocar(tester, find.byTooltip(Textos.ocultarMontos));
      expect(find.text('S/ 1,350'), findsNothing);
      expect(find.text(Textos.montoOculto), findsWidgets);
      await tocar(tester, find.byTooltip(Textos.mostrarMontos));

      // Con la venta de hoy ya anotada, otra más va por el + (mejora 01).
      expect(find.text(Textos.anotarVentaDeHoy), findsNothing);
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.atajoVentaDelDia));
      expect(find.text(Textos.hoyYaAnotaste('S/ 350')), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), '120');
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(find.text(Textos.guardadoAhoraTienes('S/ 1,470')), findsOneWidget);
      expect(find.text('S/ 1,470'), findsOneWidget);
    });

    testWidgets('Con la letra del sistema al 150 % nada se desborda', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      expect(tester.takeException(), isNull);
      for (final pestana in [
        Textos.pestanaHistorial,
        Textos.pestanaInformes,
        Textos.pestanaMoca,
      ]) {
        await tocar(tester, find.text(pestana).last);
        expect(tester.takeException(), isNull, reason: pestana);
      }
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      expect(tester.takeException(), isNull, reason: 'S06');
      await tocar(tester, find.text(Textos.escribirlo));
      await tocar(tester, find.text(Textos.salio));
      expect(tester.takeException(), isNull, reason: 'Escribirlo');
      await tocar(tester, find.byType(BotonVolver));

      await abrirAjusteOculto(tester);
      await tocarEnAjuste(tester, Textos.saltarPrimeraSemana);
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));
      expect(find.text(Textos.tienesHoy), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'S04');
    });
  });

  group('Voz', () {
    Future<void> decir(WidgetTester tester, List<AlternativaVoz> frase) async {
      _loQueDice = frase;
      final explicacion = find.text(Textos.empezarAEscuchar);
      if (explicacion.evaluate().isNotEmpty) await tocar(tester, explicacion);
    }

    Future<void> abrirVozLibre(WidgetTester tester) async {
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.decirloConVoz));
    }

    testWidgets('La primera venta dicha por voz va por cuenta', (tester) async {
      final base = await abrirApp(tester);
      await tocar(tester, find.text(Textos.anotarPrimeraVenta));
      expect(find.text(Textos.microfonoExplicacion), findsOneWidget);
      await decir(tester, [
        const AlternativaVoz('Hoy vendí 350 en efectivo y 120 por Yape'),
      ]);

      expect(find.text(Textos.mocaEntendio), findsOneWidget);
      expect(find.text('S/\u00A0350'), findsOneWidget);
      expect(find.text('S/\u00A0120'), findsOneWidget);
      expect(find.text('S/\u00A0470'), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));

      expect(find.text(Textos.hoyEntraron('S/\u00A0470')), findsOneWidget);
      final movimientos = await tester.runAsync(
        () => base.select(base.movimientos).get(),
      );
      expect(movimientos!.map((m) => m.fuente).toSet(), {Fuente.voz});
    });

    testWidgets('«Me prestaron» avisa que un préstamo no es venta '
        '(entrega 14.14)', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [
        const AlternativaVoz('Me prestaron 2000 en efectivo'),
      ]);
      expect(find.text(Textos.prestamoNoEsVenta), findsOneWidget);
      expect(find.text(Textos.puseDeMiBolsillo), findsOneWidget);
      expect(find.text(Textos.mocaEntendio), findsOneWidget);
    });

    testWidgets('Con duda del monto, Moca pregunta (S18) y no adivina', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [
        const AlternativaVoz('Pagué trescientos quince de mercadería', 0.4),
        const AlternativaVoz('Pagué trescientos cincuenta de mercadería'),
      ]);

      expect(find.text(Textos.noEscucheElMonto), findsOneWidget);
      expect(find.text(Textos.mocaNuncaAdivina), findsOneWidget);
      expect(find.text(Textos.otroMonto), findsOneWidget);
      await tocar(tester, find.text('S/\u00A0350'));

      expect(
        find.text(Textos.deDondeSalioMonto('S/\u00A0350')),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.efectivo));

      expect(find.text(Textos.mocaEntendio), findsOneWidget);
      expect(find.text('Mercadería'), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A01,000')),
        findsOneWidget,
      );
    });

    testWidgets('«Otro monto» deja escribirlo', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [const AlternativaVoz('Pagué trescientos… de luz')]);
      await tocar(tester, find.text(Textos.otroMonto));
      await tester.enterText(find.byType(TextField), '320');
      await tocar(tester, find.text(Textos.confirmarMonto));
      expect(
        find.text(Textos.deDondeSalioMonto('S/\u00A0320')),
        findsOneWidget,
      );
    });

    testWidgets('Si falta la cuenta la pregunta, y «Corregir un dato» abre '
        'la venta escrita con los montos', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [const AlternativaVoz('vendí 200')]);

      expect(find.text(Textos.dondeEntro('S/\u00A0200')), findsOneWidget);
      await tocar(tester, find.text(Textos.yape));
      expect(find.text('Venta del día'), findsOneWidget);

      await tocar(tester, find.text(Textos.corregirUnDato));
      expect(find.text(Textos.cuantoVendisteHoy), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('Entrega 49: «Le fié 50 a doña Rosa» queda como lo que te '
        'deben, sin preguntar la cuenta', (tester) async {
      final base = await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [const AlternativaVoz('Le fié 50 a doña Rosa')]);

      expect(find.text(Textos.mocaEntendio), findsOneWidget);
      expect(find.text(Textos.todaviaMeDebe), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Doña Rosa'), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.pump(const Duration(seconds: 5));

      final movimientos = await tester.runAsync(
        () => base.select(base.movimientos).get(),
      );
      final fiado = movimientos!.singleWhere((m) => m.montoCentimos == 5000);
      expect(fiado.estadoPago, EstadoPago.pendiente);
      expect(fiado.fuente, Fuente.voz);
      final quien = await tester.runAsync(
        () => (base.select(
          base.contrapartes,
        )..where((c) => c.id.equals(fiado.contraparteId!))).getSingle(),
      );
      expect(quien!.nombre, 'Doña Rosa');
    });

    testWidgets('Entrega 49: si no dijo a quién le fió, Moca lo pregunta', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [const AlternativaVoz('Vendí 80 al fiado')]);

      expect(find.text(Textos.quienTeDebe), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Juan');
      await tester.pump();
      await tocar(tester, find.text(Textos.continuar));
      expect(find.text(Textos.mocaEntendio), findsOneWidget);
      expect(find.text(Textos.todaviaMeDebe), findsOneWidget);
    });

    testWidgets('Entrega 49: una compra al crédito queda como lo que debes; '
        '«Corregir un dato» la abre igual', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [
        const AlternativaVoz('Le debo 100 a don Pepe de mercadería'),
      ]);

      expect(find.text(Textos.mocaEntendio), findsOneWidget);
      expect(find.text(Textos.todaviaLoDebo), findsOneWidget);
      await tocar(tester, find.text(Textos.corregirUnDato));
      expect(find.text(Textos.queFue), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Don Pepe'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    // La segunda vez, la voz escucha al abrir: la frase va antes.
    Future<void> hablar(WidgetTester tester, String frase) async {
      _loQueDice = [AlternativaVoz(frase)];
      await abrirVozLibre(tester);
      await decir(tester, [AlternativaVoz(frase)]);
    }

    Future<void> fiarPorVoz(WidgetTester tester, String frase) async {
      await hablar(tester, frase);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.pump(const Duration(seconds: 5));
      await esperar(tester);
    }

    testWidgets('Entrega 50: «Cobré 30 del fiado de doña Rosa» descuenta su '
        'deuda', (tester) async {
      final base = await abrirApp(tester, listo: true);
      await fiarPorVoz(tester, 'Le fié 80 a doña Rosa');
      await hablar(tester, 'Cobré 30 del fiado de doña Rosa en efectivo');

      expect(
        find.text(Textos.teDebeEsDeEsa('Doña Rosa', 'S/\u00A080')),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.siDeEsaDeuda));
      expect(find.text(Textos.cobroDeLoQueTeDebe('Doña Rosa')), findsOneWidget);
      expect(find.textContaining(Textos.leQueda('S/\u00A050')), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.cobradoParte('S/\u00A030', 'Doña Rosa', 'S/\u00A050')),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));

      final movimientos = await tester.runAsync(
        () => base.select(base.movimientos).get(),
      );
      final deudaDeRosa = movimientos!.singleWhere(
        (m) => m.estadoPago == EstadoPago.pendiente,
      );
      expect(deudaDeRosa.montoCentimos, 5000);
      final parte = movimientos.singleWhere((m) => m.abonaA != null);
      expect(parte.abonaA, deudaDeRosa.id);
      expect(parte.montoCentimos, 3000);
      expect(parte.estadoPago, EstadoPago.pagado);
    });

    testWidgets('Entrega 50: sin nombre se elige a quién; de más, no se '
        'descuenta solo', (tester) async {
      final base = await abrirApp(tester, listo: true);
      await fiarPorVoz(tester, 'Le fié 80 a doña Rosa');
      await fiarPorVoz(tester, 'Le fié 20 a Juan');
      await hablar(tester, 'Cobré 100 del fiado en efectivo');

      expect(find.text(Textos.deQuienEsElCobro), findsOneWidget);
      expect(
        find.text(Textos.quienYCuanto('Juan', 'S/\u00A020')),
        findsOneWidget,
      );
      await tocar(
        tester,
        find.text(Textos.quienYCuanto('Doña Rosa', 'S/\u00A080')),
      );
      expect(
        find.text(
          Textos.teDebeNoTanto('Doña Rosa', 'S/\u00A080', 'S/\u00A0100'),
        ),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.cobrarLos('S/\u00A080')));
      expect(find.textContaining(Textos.yaNoDebeNada), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.pump(const Duration(seconds: 5));

      final movimientos = await tester.runAsync(
        () => base.select(base.movimientos).get(),
      );
      final pendientes = movimientos!.where(
        (m) => m.estadoPago == EstadoPago.pendiente,
      );
      expect(pendientes.single.montoCentimos, 2000);
    });

    testWidgets('Entrega 50: «Corregir un dato» abre la deuda con «Ya me '
        'pagó»', (tester) async {
      await abrirApp(tester, listo: true);
      await fiarPorVoz(tester, 'Le fié 80 a doña Rosa');
      await hablar(tester, 'Doña Rosa me pagó 30 en efectivo');
      await tocar(tester, find.text(Textos.siDeEsaDeuda));
      await tocar(tester, find.text(Textos.corregirUnDato));
      expect(
        find.widgetWithText(FilledButton, Textos.yaMePago),
        findsOneWidget,
      );
    });

    testWidgets('Entrega 50: «No, anotarlo aparte» lo anota como siempre', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await fiarPorVoz(tester, 'Le fié 80 a doña Rosa');
      await hablar(tester, 'Cobré 30 del fiado de doña Rosa en efectivo');
      await tocar(tester, find.text(Textos.noAnotarloAparte));
      expect(find.text('Cobro de fiado'), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.pump(const Duration(seconds: 5));
      final movimientos = await tester.runAsync(
        () => base.select(base.movimientos).get(),
      );
      expect(
        movimientos!
            .singleWhere((m) => m.estadoPago == EstadoPago.pendiente)
            .montoCentimos,
        8000,
      );
      expect(movimientos.where((m) => m.abonaA != null), isEmpty);
    });

    testWidgets('Entrega 50: «Le pagué 100 a don Pepe» paga lo que le debes', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await fiarPorVoz(tester, 'Le debo 100 a don Pepe de mercadería');
      await hablar(tester, 'Le pagué 100 a don Pepe en efectivo');
      expect(
        find.text(Textos.leDebesEsDeEsa('Don Pepe', 'S/\u00A0100')),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.siDeEsaDeuda));
      expect(find.textContaining(Textos.yaNoLeDebesNada), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.pump(const Duration(seconds: 5));
      final movimientos = await tester.runAsync(
        () => base.select(base.movimientos).get(),
      );
      expect(
        movimientos!.singleWhere((m) => m.montoCentimos == 10000).estadoPago,
        EstadoPago.pagado,
      );
      expect(
        movimientos.where((m) => m.estadoPago != EstadoPago.pagado),
        isEmpty,
      );
    });

    testWidgets('«Saqué 100 para mí» se guarda como retiro', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [
        const AlternativaVoz('Saqué 100 para mí del efectivo'),
      ]);
      expect(find.text(Textos.retiroParaMi), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A01,250')),
        findsOneWidget,
      );
    });

    testWidgets('Si no entiende, lo dice y deja intentar otra vez', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      await decir(tester, [const AlternativaVoz('hola, ¿cómo estás?')]);
      expect(find.text(Textos.noTeEntendi), findsOneWidget);

      _loQueDice = [const AlternativaVoz('pagué 80 de luz en efectivo')];
      await tocar(tester, find.text(Textos.decirloOtraVez));
      expect(find.text(Textos.mocaEntendio), findsOneWidget);
    });

    testWidgets('Sin permiso del micrófono, ofrece escribirlo', (tester) async {
      await abrirApp(tester, listo: true);
      _vozDisponible = DisponibilidadVoz.sinPermiso;
      await abrirVozLibre(tester);
      await decir(tester, [const AlternativaVoz('vendí 200')]);
      expect(find.text(Textos.sinPermisoMicrofono), findsOneWidget);
      await tocar(tester, find.text(Textos.prefieroEscribirlo));
      expect(find.text(Textos.queFue), findsOneWidget);
    });

    testWidgets('La voz no se desborda con letra grande', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      await abrirVozLibre(tester);
      expect(tester.takeException(), isNull, reason: 'Explicación');
      await decir(tester, [
        const AlternativaVoz('Pagué trescientos quince de mercadería', 0.4),
        const AlternativaVoz('Pagué trescientos cincuenta de mercadería'),
      ]);
      expect(tester.takeException(), isNull, reason: 'S18');
      await tocar(tester, find.text('S/\u00A0350'));
      await tocar(tester, find.text(Textos.efectivo));
      expect(tester.takeException(), isNull, reason: 'Moca entendió');
    });
  });

  group('Foto y QR', () {
    Future<void> tomarFoto(WidgetTester tester) async {
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.tomarFoto));
    }

    FilledButton guardar(WidgetTester tester) =>
        tester.widget(find.widgetWithText(FilledButton, Textos.guardar));

    testWidgets('La foto se lee y se confirma en S08; nada se guarda sin '
        'elegir cuenta y si ya se pagó', (tester) async {
      await abrirApp(tester, listo: true);
      await tomarFoto(tester);

      expect(find.text(Textos.revisaLaLectura), findsOneWidget);
      expect(find.text('Distribuidora San Martín'), findsOneWidget);
      expect(find.text('S/\u00A0980'), findsOneWidget);
      expect(find.text(Textos.productos(12)), findsOneWidget);
      expect(find.text('Mercadería'), findsOneWidget);
      expect(guardar(tester).onPressed, isNull);

      // Primero si ya se pagó; la cuenta aparece después (entrega 14.10.1).
      expect(find.text(Textos.deDondeSalio), findsNothing);
      await tocar(tester, find.text(Textos.siPagado));
      expect(guardar(tester).onPressed, isNull);
      await tocar(tester, find.text(Textos.efectivo));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A0370')),
        findsOneWidget,
      );
    });

    testWidgets('«Todavía lo debo» no baja el saldo ni pregunta por '
        'negativo', (tester) async {
      final base = await abrirApp(tester, listo: true);
      await tomarFoto(tester);
      // Lo que se debe no pregunta de dónde salió: eso se elige al pagarlo.
      await tocar(tester, find.text(Textos.todaviaLoDebo));
      expect(find.text(Textos.deDondeSalio), findsNothing);
      expect(find.text(Textos.cuentaAlPagar), findsOneWidget);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A01,350')),
        findsOneWidget,
      );
      final deudas = await tester.runAsync(
        () => (base.select(
          base.movimientos,
        )..where((m) => m.estadoPago.equalsValue(EstadoPago.pendiente))).get(),
      );
      expect(deudas, hasLength(1));
    });

    testWidgets('Pagado desde una cuenta sin plata, Moca pregunta', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await tomarFoto(tester);
      await tocar(tester, find.text(Textos.siPagado));
      await tocar(tester, find.text(Textos.yape));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(find.text(Textos.quedariaNegativoTitulo), findsOneWidget);
    });

    testWidgets('Foto ilegible (S17): lo que se leyó, consejos y completar '
        'a mano', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocarEnAjuste(tester, Textos.forzarFotoIlegible);
      expect(find.text(Textos.fotoIlegibleForzada), findsOneWidget);
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));

      await tomarFoto(tester);
      expect(find.text(Textos.fotoBorrosa), findsOneWidget);
      expect(find.text('S/\u00A0980'), findsOneWidget);
      expect(find.text(Textos.noSeLee), findsNWidgets(2));
      expect(find.text(Textos.consejoSombra), findsOneWidget);

      await tocar(tester, find.text(Textos.completarAMano));
      expect(find.text(Textos.completadoAMano), findsOneWidget);
      expect(find.text(Textos.eligeTipoDeGasto), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'Bodega Mayorista');
      await tocar(tester, find.text(Textos.eligeTipoDeGasto));
      await tocar(tester, find.text('Otros'));
      await tocar(tester, find.text(Textos.siPagado));
      await tocar(tester, find.text(Textos.efectivo));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A0370')),
        findsOneWidget,
      );

      // La siguiente foto ya se lee bien.
      await tomarFoto(tester);
      expect(find.text(Textos.fotoBorrosa), findsNothing);
    });

    testWidgets('Entrega 14: sin señal, «Intentar otra vez» lee la misma '
        'foto', (tester) async {
      await abrirApp(tester, listo: true);
      _lecturas.addAll([
        const FotoNoLeida(ProblemaLectura.sinSenal),
        const FotoLeida(
          LecturaComprobante(
            origen: OrigenLectura.foto,
            emisorNombre: 'Grifo Santa Rosa',
            totalCentimos: 6000,
          ),
        ),
      ]);
      await tomarFoto(tester);
      expect(find.text(Textos.fotoSinSenal), findsOneWidget);
      expect(find.text(Textos.escribirloYo), findsOneWidget);
      await tocar(tester, find.text(Textos.intentarOtraVez));
      expect(find.text(Textos.leidoDeLaFoto), findsOneWidget);
      expect(find.text('Grifo Santa Rosa'), findsOneWidget);
    });

    testWidgets('Entrega 14: lo que no es comprobante ofrece otra foto o '
        'escribirlo', (tester) async {
      await abrirApp(tester, listo: true);
      _lecturas.add(const FotoNoLeida(ProblemaLectura.noEsComprobante));
      await tomarFoto(tester);
      expect(find.text(Textos.fotoNoEsComprobante), findsOneWidget);
      expect(find.text(Textos.tomarOtraFoto), findsOneWidget);
      await tocar(tester, find.text(Textos.escribirloYo));
      expect(find.text(Textos.queFue), findsOneWidget);
    });

    testWidgets('Entrega 14: al tope del día, solo escribirlo', (tester) async {
      await abrirApp(tester, listo: true);
      _lecturas.add(const FotoNoLeida(ProblemaLectura.limiteDiario));
      await tomarFoto(tester);
      expect(find.text(Textos.fotoLimiteDiario), findsOneWidget);
      expect(find.text(Textos.escribirloYo), findsNothing);
      await tocar(tester, find.text(Textos.escribirlo));
      expect(find.text(Textos.queFue), findsOneWidget);
    });

    testWidgets('Entrega 14: sin cuenta, ofrece guardar el avance', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      _lecturas.add(const FotoNoLeida(ProblemaLectura.sinCuenta));
      await tomarFoto(tester);
      expect(find.text(Textos.fotoSinCuenta), findsOneWidget);
      await tocar(tester, find.text(Textos.guardarMiAvance));
      expect(find.text(Textos.guardaTuAvance), findsWidgets);
    });

    testWidgets('Entrega 14.2: la foto de prueba se avisa al confirmar', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      _lecturas.add(
        const FotoLeida(
          LecturaComprobante(
            origen: OrigenLectura.foto,
            emisorNombre: 'Grifo Santa Rosa',
            totalCentimos: 6000,
            fotoDePrueba: 2,
          ),
        ),
      );
      await tomarFoto(tester);
      expect(find.text(Textos.fotoDePrueba(2, 3)), findsOneWidget);
    });

    testWidgets('Entrega 14.2: usadas las pruebas, pide guardar el avance', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(
        () => AccesoLocal(
          base,
          () => _ahora,
        ).guardarAjuste(AccesoLocal.claveFotosDePrueba, '0'),
      );
      await esperar(tester);
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      expect(find.text(Textos.guardaTuAvanceParaFotos), findsOneWidget);
      _lecturas.add(const FotoNoLeida(ProblemaLectura.pruebasAgotadas));
      await tocar(tester, find.text(Textos.tomarFoto));
      expect(find.text(Textos.fotosDePruebaAgotadas(3)), findsOneWidget);
      expect(find.text(Textos.escribirloYo), findsOneWidget);
      await tocar(tester, find.text(Textos.guardarMiAvance));
      expect(find.text(Textos.guardaTuAvance), findsWidgets);
    });

    testWidgets('Si se cancela la cámara, vuelve a Registrar', (tester) async {
      await abrirApp(tester, listo: true);
      _camara = const FotoCancelada();
      await tomarFoto(tester);
      expect(find.text(Textos.diloOMuestralo), findsOneWidget);
    });

    testWidgets('Sin permiso de cámara, ofrece escribirlo', (tester) async {
      await abrirApp(tester, listo: true);
      _camara = const CamaraSinPermiso();
      await tomarFoto(tester);
      expect(find.text(Textos.sinPermisoCamara), findsOneWidget);
      await tocar(tester, find.text(Textos.escribirlo));
      expect(find.text(Textos.queFue), findsOneWidget);
    });

    testWidgets('Un QR leído pide el tipo de gasto y muestra el RUC', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      final contexto = tester.element(find.byType(BarraInferior));
      GoRouter.of(contexto).push(
        Rutas.confirmarLectura,
        extra: LecturaComprobante(
          origen: OrigenLectura.qr,
          emisorIdentificacion: '20100070970',
          tipo: 'Factura',
          serie: 'F001',
          numero: '12345',
          totalCentimos: 14230,
          fechaEmision: DateTime(2026, 10, 8),
        ),
      );
      await esperar(tester);

      expect(find.text('S/\u00A0142.30'), findsOneWidget);
      expect(find.text('Factura · jueves 8 de octubre'), findsOneWidget);
      expect(find.text(Textos.rucDe('20100070970')), findsOneWidget);
      expect(find.text(Textos.leidoDelQr), findsOneWidget);
      await tocar(tester, find.text(Textos.siPagado));
      await tocar(tester, find.text(Textos.efectivo));
      expect(guardar(tester).onPressed, isNull);
      await tocar(tester, find.text(Textos.eligeTipoDeGasto));
      await tocar(
        tester,
        find.text('Servicios (luz, agua, internet, teléfono)'),
      );
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(
        find.text(Textos.guardadoAhoraTienes('S/\u00A01,208')),
        findsOneWidget,
      );
    });

    testWidgets('S08 y S17 no se desbordan con letra grande', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      await tomarFoto(tester);
      expect(tester.takeException(), isNull, reason: 'S08');
      await tocar(tester, find.byType(BotonVolver));
      await abrirAjusteOculto(tester);
      await tocarEnAjuste(tester, Textos.forzarFotoIlegible);
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));
      await tomarFoto(tester);
      expect(find.text(Textos.fotoBorrosa), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'S17');
    });
  });

  testWidgets('Las pantallas del primer día no se desbordan con letra grande', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await abrirApp(tester);
    expect(tester.takeException(), isNull, reason: 'S00');
    await tocar(tester, find.text(Textos.anotarPrimeraVenta));
    expect(tester.takeException(), isNull, reason: 'Voz');
    await tocar(tester, find.text(Textos.prefieroEscribirlo));
    expect(tester.takeException(), isNull, reason: 'S07');
    await tester.enterText(find.byType(TextField).at(0), '350');
    await tester.pump();
    await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
    expect(tester.takeException(), isNull, reason: 'S01');
    await tocar(tester, find.text(Textos.ahoraNo));
    expect(tester.takeException(), isNull, reason: 'S02');
  });

  group('Historial', () {
    Future<void> abrirHistorial(WidgetTester tester) =>
        tocar(tester, find.text(Textos.pestanaHistorial));

    Future<void> anotarGasto(WidgetTester tester, String monto) async {
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      await tocar(tester, find.text(Textos.salio));
      await tester.enterText(find.byType(TextField).first, monto);
      await tester.pump();
      await tocar(tester, find.text('Otros'));
      await tester.enterText(find.byType(TextField).last, 'Bolsas');
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
    }

    testWidgets('Mejora 01: «Pendientes», el total del día sin lo fiado y '
        '«Eso es todo»', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      await tocar(tester, find.text(Textos.entro).first);
      await tester.enterText(find.byType(TextField).first, '80');
      await tester.pump();
      await tocar(tester, find.text(Textos.todaviaMeDebe));
      await tester.enterText(
        find.widgetWithText(TextField, Textos.quienTeDebeEjemplo),
        'Doña Rosa',
      );
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.pump(const Duration(seconds: 5));
      await abrirHistorial(tester);

      // El total de hoy cuenta la venta (S/ 350), no lo fiado.
      expect(find.text('+ S/ 350'), findsNWidgets(2));
      expect(find.text('+ S/ 430'), findsNothing);
      expect(find.text(Textos.teDebe), findsOneWidget);
      expect(find.text(Textos.esoEsTodo), findsOneWidget);

      await tocar(tester, find.text(Textos.filtroPendientes(1)));
      expect(find.text('Doña Rosa'), findsOneWidget);
      // La venta pagada no está, y el día no suma lo fiado.
      expect(find.text('+ S/ 350'), findsNothing);
      expect(find.text(Textos.esoEsTodo), findsNothing);
    });

    testWidgets('Muestra lo anotado por día, con filtros', (tester) async {
      await abrirApp(tester, listo: true);
      await anotarGasto(tester, '80');
      await abrirHistorial(tester);

      expect(find.text('Hoy · lunes 12'), findsOneWidget);
      expect(find.text('Venta del día'), findsOneWidget);
      // La fila y el total del día (mejora 01).
      expect(find.text('+ S/ 350'), findsNWidgets(2));
      expect(find.text('Bolsas'), findsOneWidget);
      expect(find.text('Otros · Efectivo'), findsOneWidget);
      expect(find.text('− S/ 80'), findsNWidgets(2));

      await tocar(tester, find.text(Textos.entro));
      expect(find.text('Bolsas'), findsNothing);
      expect(find.text('Venta del día'), findsOneWidget);
      await tocar(tester, find.text(Textos.salio));
      expect(find.text('Venta del día'), findsNothing);
      await tocar(tester, find.text(Textos.filtroPorSubir(0)));
      expect(find.text(Textos.nadaPorSubir), findsOneWidget);
    });

    testWidgets('Sin señal se avisa y lo guardado queda por subir', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      _conSenal = false;
      // La señal se lee al abrir: se simula desde el ajuste oculto.
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.simularSinSenal));
      expect(find.text(Textos.sinSenalSimulada), findsOneWidget);
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));

      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      expect(find.text(Textos.sinSenal), findsOneWidget);
      await tocar(tester, find.text(Textos.escribirlo));
      expect(find.text(Textos.sinSenal), findsOneWidget);
      await tocar(tester, find.text(Textos.salio));
      await tester.enterText(find.byType(TextField).first, '80');
      await tester.pump();
      await tocar(tester, find.text('Otros'));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));

      await abrirHistorial(tester);
      expect(find.text(Textos.filtroPorSubir(1)), findsOneWidget);
      // «Por subir» va como etiqueta, no repetido en el texto (mejora 01).
      expect(find.text('Efectivo'), findsWidgets);
      expect(find.text(Textos.porSubirEtiqueta), findsOneWidget);
      await tocar(tester, find.text('Otros'));
      expect(find.text(Textos.guardadoPorSubir), findsOneWidget);
    });

    testWidgets('Corregir guarda los cambios y los muestra en «Cambios»', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirHistorial(tester);
      await tocar(tester, find.text('Venta del día'));

      expect(find.text(Textos.tituloDetalle), findsOneWidget);
      expect(find.text(Textos.comoSeAnoto(Fuente.texto)), findsOneWidget);
      expect(find.text(Textos.anotado(Fuente.texto)), findsOneWidget);

      await tocar(tester, find.text(Textos.corregir));
      expect(find.text(Textos.corregirRegistro), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '400');
      await tocar(tester, find.text(Textos.yape));
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.guardarCambios),
      );

      expect(find.text(Textos.cambiosGuardados('S/ 1,400')), findsOneWidget);
      expect(find.text('+ S/ 400'), findsOneWidget);
      expect(
        find.text(Textos.cambiasteMonto('S/ 350', 'S/ 400')),
        findsOneWidget,
      );
      expect(
        find.text(Textos.cambiasteCuenta(Textos.efectivo, Textos.yape)),
        findsOneWidget,
      );

      await tocar(tester, find.byType(BotonVolver));
      expect(find.text('+ S/ 400'), findsNWidgets(2));
      expect(find.text('+ S/ 350'), findsNothing);
    });

    testWidgets('Deshacer desde el detalle pregunta y quita el registro', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await anotarGasto(tester, '80');
      await abrirHistorial(tester);
      await tocar(tester, find.text('Bolsas'));
      await tocar(tester, find.text(Textos.deshacerRegistro));
      expect(
        find.text(Textos.deshacerConSaldo(Textos.efectivo, 'S/ 1,350')),
        findsOneWidget,
      );
      await tocar(tester, find.widgetWithText(TextButton, Textos.deshacer));
      expect(find.text(Textos.registroDeshecho), findsOneWidget);
      expect(find.text('Bolsas'), findsNothing);
      expect(find.text(Textos.filtroTodo), findsOneWidget);
    });

    testWidgets('«Ya lo pagué» pide cuenta y día y quita «Lo debes»', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        final egresos = await base.select(base.categorias).get();
        await RepositorioComprobantesLocal(
          base,
          ahora: () => _ahora,
        ).guardarCompra(
          CompraConfirmada(
            lectura: const LecturaComprobante(
              origen: OrigenLectura.qr,
              emisorIdentificacion: '20100070970',
              tipo: 'Factura',
              serie: 'F001',
              numero: '12345',
              totalCentimos: 98050,
            ),
            totalCentimos: 98050,
            cuenta: TipoCuenta.efectivo,
            pagado: false,
            categoriaId: egresos.firstWhere((c) => c.nombre == 'Mercadería').id,
            emisorNombre: 'Distribuidora San Martín',
            fecha: DateTime(2026, 10, 8),
          ),
        );
      });
      await abrirHistorial(tester);
      expect(find.text('Distribuidora San Martín'), findsOneWidget);
      expect(find.textContaining(Textos.loDebes), findsOneWidget);

      await tocar(tester, find.text('Distribuidora San Martín'));
      expect(find.text(Textos.todaviaLoDebes), findsOneWidget);
      expect(find.text('Total S/ 980.50'), findsOneWidget);
      expect(find.text('Factura F001-12345'), findsOneWidget);

      await tocar(tester, find.widgetWithText(FilledButton, Textos.yaLoPague));
      expect(find.text(Textos.conQuePagaste), findsOneWidget);
      // El primer día de pago es hoy: no se ofrece «Ayer».
      expect(find.text(Textos.ayer), findsNothing);
      await tocar(tester, find.text(Textos.yape).last);
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.yaLoPague).last,
      );
      // Yape no tiene plata: Moca pregunta.
      await tocar(tester, find.text(Textos.guardarIgual));

      expect(
        find.text(Textos.pagadoAhoraTienes('−S/ 981', Textos.yape)),
        findsOneWidget,
      );
      expect(find.text(Textos.todaviaLoDebes), findsNothing);
      expect(
        find.text(Textos.pagaste(Textos.yape, '12 de octubre')),
        findsOneWidget,
      );
      expect(find.text(Textos.yaLoPague), findsNothing);
    });

    testWidgets('El Historial y el detalle no se desbordan con letra grande', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      await anotarGasto(tester, '80');
      await abrirHistorial(tester);
      expect(tester.takeException(), isNull, reason: 'S10');
      await tocar(tester, find.text('Bolsas'));
      expect(tester.takeException(), isNull, reason: 'Detalle');
      await tocar(tester, find.text(Textos.corregir));
      expect(tester.takeException(), isNull, reason: 'Corregir');
    });
  });

  group('Arqueo', () {
    Future<void> abrirArqueoDesdeElPrimerDia(WidgetTester tester) async {
      // Con letra grande, el paso queda más abajo de la pantalla.
      await tester.scrollUntilVisible(
        find.text(Textos.pasoPrimerArqueo),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.pasoPrimerArqueo));
      expect(find.text(Textos.arqueoDeLaSemana), findsOneWidget);
    }

    FilledButton guardarArqueo(WidgetTester tester) =>
        tester.widget(find.widgetWithText(FilledButton, Textos.guardarArqueo));

    testWidgets('Propone lo calculado; una diferencia se explica y se guarda', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirArqueoDesdeElPrimerDia(tester);

      expect(find.text(Textos.arqueoDetalle), findsOneWidget);
      expect(find.text(Textos.cuadra), findsNWidgets(3));
      expect(guardarArqueo(tester).onPressed, isNotNull);

      await tester.enterText(find.byType(TextField).first, '1270');
      await esperar(tester);
      expect(find.text(Textos.faltan('S/ 80')), findsOneWidget);
      expect(
        find.text(Textos.preguntaFaltan('S/ 80', Textos.efectivo)),
        findsOneWidget,
      );
      expect(guardarArqueo(tester).onPressed, isNull);

      await tocar(
        tester,
        find.text(Textos.motivoArqueo(MotivoArqueo.retiroParaMi)),
      );
      expect(
        find.text(Textos.notaMotivo(MotivoArqueo.retiroParaMi, faltan: true)),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.guardarArqueo));

      expect(find.text(Textos.arqueoGuardado('S/ 1,270')), findsOneWidget);
      // Con el primer arqueo, el Inicio pasa a ser el completo (S04).
      expect(find.text(Textos.tienesHoy), findsOneWidget);
      expect(find.text(Textos.hacerArqueo), findsOneWidget);
      expect(find.textContaining(Textos.mocaArqueoHecho), findsOneWidget);
      await tocar(tester, find.text(Textos.pestanaHistorial));
      expect(find.text(Textos.retiroParaMi), findsOneWidget);
    });

    testWidgets('«Un gasto que olvidé» pide la categoría', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirArqueoDesdeElPrimerDia(tester);
      await tester.enterText(find.byType(TextField).first, '1270');
      await esperar(tester);
      await tocar(
        tester,
        find.text(Textos.motivoArqueo(MotivoArqueo.gastoOlvidado)),
      );
      expect(guardarArqueo(tester).onPressed, isNull);
      await tocar(tester, find.text('Otros'));
      expect(guardarArqueo(tester).onPressed, isNotNull);
    });

    testWidgets('Si sobra plata, ofrece «Una venta que no anoté»', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirArqueoDesdeElPrimerDia(tester);
      await tester.enterText(find.byType(TextField).at(1), '50');
      await esperar(tester);
      expect(find.text(Textos.sobran('S/ 50')), findsOneWidget);
      expect(
        find.text(Textos.motivoArqueo(MotivoArqueo.ventaNoAnotada)),
        findsOneWidget,
      );
      expect(
        find.text(Textos.motivoArqueo(MotivoArqueo.retiroParaMi)),
        findsNothing,
      );
    });

    testWidgets('«No lo sé» deja un ajuste en el Historial que no se corrige', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirArqueoDesdeElPrimerDia(tester);
      await tester.enterText(find.byType(TextField).first, '1270');
      await esperar(tester);
      await tocar(tester, find.text(Textos.motivoArqueo(MotivoArqueo.noLoSe)));
      await tocar(tester, find.text(Textos.guardarArqueo));

      await tocar(tester, find.text(Textos.pestanaHistorial));
      expect(find.text(Textos.ajusteDelArqueo), findsOneWidget);
      expect(
        find.text('${Textos.ajusteNoCuenta} · ${Textos.efectivo}'),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.salio));
      expect(find.text(Textos.ajusteDelArqueo), findsNothing);
      await tocar(tester, find.text(Textos.filtroTodo));

      await tocar(tester, find.text(Textos.ajusteDelArqueo));
      expect(find.text(Textos.ajusteExplicacion), findsOneWidget);
      expect(
        find.text(Textos.motivoArqueo(MotivoArqueo.noLoSe)),
        findsOneWidget,
      );
      expect(find.text(Textos.corregir), findsNothing);
      expect(find.text(Textos.deshacerRegistro), findsNothing);
    });

    testWidgets('«Pedir el arqueo ahora» muestra la tarjeta en el Inicio', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocarEnAjuste(tester, Textos.saltarPrimeraSemana);
      await tocar(tester, find.text(Textos.pedirArqueo));
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));

      expect(find.text(Textos.mocaTocaArqueo), findsOneWidget);
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.hacerArqueo),
      );
      expect(find.text(Textos.arqueoDeLaSemana), findsOneWidget);
    });

    testWidgets('El arqueo no se desborda con letra grande', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      await abrirArqueoDesdeElPrimerDia(tester);
      await tester.enterText(find.byType(TextField).first, '1270');
      await esperar(tester);
      await tocar(
        tester,
        find.text(Textos.motivoArqueo(MotivoArqueo.gastoOlvidado)),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Informe y Moca', () {
    testWidgets('Entrega 38: se toca una categoría y «Lo que debes»', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaInformes));
      await tester.scrollUntilVisible(
        find.text(Textos.conQueEntro),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text('Venta del día'));
      expect(
        find.text(Textos.totalDeRegistros(formatearSoles(35000), 1)),
        findsOneWidget,
      );
      await tocar(tester, find.byType(BotonVolver));
      await tester.scrollUntilVisible(
        find.text(Textos.loQueDebesTitulo),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.loQueDebesTitulo));
      expect(find.text(Textos.noDebesNada), findsOneWidget);
    });

    testWidgets('Entrega 40: el resumen del año, sus meses y categorías', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaInformes));
      await tocar(tester, find.text(Textos.verAnio));
      expect(find.text('${_ahora.year}'), findsOneWidget);
      // Empezó el 12: el año va desde ese día hasta hoy.
      expect(
        find.text(
          Textos.periodoDelAnio(
            DateTime(_ahora.year, _ahora.month, 12),
            enCurso: true,
          ),
          skipOffstage: false,
        ),
        findsWidgets,
      );
      expect(find.text(Textos.enElAnioCrecio(_ahora.year)), findsOneWidget);
      // Ni el año anterior ni el siguiente: no hay Moca antes ni después.
      for (final etiqueta in [Textos.anioAnterior, Textos.anioSiguiente]) {
        final flecha = tester.widget<IconButton>(
          find.ancestor(
            of: find.byTooltip(etiqueta),
            matching: find.byType(IconButton),
          ),
        );
        expect(flecha.onPressed, isNull, reason: etiqueta);
      }
      // Los meses de antes salen en gris; el actual, hasta hoy.
      await tester.scrollUntilVisible(
        find.text(Textos.hastaHoyMinuscula),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(Textos.antesDeMoca, skipOffstage: false),
        findsNWidgets(_ahora.month - 1),
      );
      // Una categoría del año abre sus registros del año.
      await tester.scrollUntilVisible(
        find.text('Venta del día'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text('Venta del día'));
      expect(
        find.text(Textos.totalDeRegistros(formatearSoles(35000), 1)),
        findsOneWidget,
      );
      await tocar(tester, find.byType(BotonVolver));
      // Tocar el mes abre su informe.
      await tester.scrollUntilVisible(
        find.text(Textos.hastaHoyMinuscula),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.hastaHoyMinuscula));
      expect(find.text(Textos.comoSeMovio), findsOneWidget);
      expect(find.text(Textos.desdeElDiaHastaHoy(12)), findsOneWidget);
    });

    testWidgets('El informe del primer mes', (tester) async {
      await abrirApp(tester, listo: true);
      // En el Inicio, «Tienes hoy» es desde que empezó (entrega 36).
      expect(find.text(Textos.desdeQueEmpezaste), findsOneWidget);
      await tocar(tester, find.text(Textos.pestanaInformes));
      expect(find.text('Octubre'), findsOneWidget);
      expect(find.text(Textos.desdeElDiaHastaHoy(12)), findsOneWidget);
      // Flujo de caja, no ganancia (entrega 14.9): empezó el 12 con
      // S/ 1,000 y la venta de S/ 350 lo deja en lo que tiene hoy.
      expect(find.text(Textos.tuPlataCrecio), findsOneWidget);
      expect(find.text(Textos.primerMesConMoca), findsOneWidget);
      expect(find.text(Textos.comoSeMovio), findsOneWidget);
      // La nota del periodo bajo cada título (entrega 36).
      expect(
        find.text(
          Textos.periodoDelMes(
            DateTime(_ahora.year, _ahora.month),
            enCurso: true,
            hoy: _ahora,
            desdeDia: 12,
          ),
          skipOffstage: false,
        ),
        findsWidgets,
      );
      expect(find.text(Textos.empezasteCon), findsOneWidget);
      expect(find.text(formatearSoles(100000)), findsOneWidget);
      expect(find.text(Textos.tienesHoy), findsOneWidget);
      expect(find.text(formatearSoles(135000)), findsOneWidget);
      // Con qué entró la plata (entrega 35): la venta del día, antes de los
      // gastos.
      await tester.scrollUntilVisible(
        find.text(Textos.conQueEntro),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Venta del día'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(Textos.conQueEntro)).dy,
        lessThan(
          tester
              .getTopLeft(find.text(Textos.enQueSeFue, skipOffstage: false))
              .dy,
        ),
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await esperar(tester);
      final anterior = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(Textos.mesAnterior),
          matching: find.byType(IconButton),
        ),
      );
      expect(anterior.onPressed, isNull);
      expect(find.text(Textos.compartir), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(Textos.sinPapel(100)),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(Textos.sinPapel(100)), findsOneWidget);
    });

    testWidgets('El PDF del informe se arma en el teléfono, para quien '
        'el dueño elija', (tester) async {
      await abrirApp(tester, listo: true);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final repositorio = container.read(repositorioInformeProvider);
      final bytes = await tester.runAsync(() async {
        final informe = await repositorio.observarMes(null).first;
        final detalle = await repositorio.detalleParaPdf(informe);
        return [
          for (final destino in DestinoInforme.values)
            await armarPdfDelInforme(
              informe,
              detalle,
              destino: destino,
              nombreNegocio: 'Bodega Don Lucho',
              hoy: _ahora,
            ),
        ];
      });
      for (final b in bytes!) {
        expect(String.fromCharCodes(b.take(4)), '%PDF');
      }
      expect(
        nombreDelPdf('Bodega Don Lucho', DateTime(2026, 10)),
        'Moca-Bodega-Don-Lucho-octubre-2026.pdf',
      );

      // «Compartir» → «Compartir PDF» pregunta para quién es (mejora 01).
      await tocar(tester, find.text(Textos.pestanaInformes));
      await tocar(tester, find.text(Textos.compartir));
      await tocar(tester, find.text(Textos.compartirPdf));
      expect(find.text(Textos.paraQuienEsPdf), findsOneWidget);
      expect(find.text(Textos.pdfParaMi), findsOneWidget);
      expect(find.text(Textos.pdfParaContador), findsOneWidget);
      expect(find.text(Textos.pdfParaCredito), findsOneWidget);
      expect(find.text(Textos.planFull), findsOneWidget);
      // Para la caja, primero dice qué llenó Moca (entrega 14.15).
      await tocar(tester, find.text(Textos.pdfParaCredito));
      expect(
        find.text(Textos.flujoParaCaja(1, hastaHoy: 'octubre')),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.cancelar));
      expect(
        find.text(Textos.flujoParaCaja(1, hastaHoy: 'octubre')),
        findsNothing,
      );
      await esperar(tester);
      // Y en la misma hoja, el Excel de las operaciones (entrega 14.13).
      await tocar(tester, find.text(Textos.compartir));
      expect(find.text(Textos.compartirExcel), findsOneWidget);
    });

    testWidgets('Moca resume la semana y la lee en voz alta', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      final texto = '${Textos.estaSemanaQueda('S/ 350')}.';
      expect(find.text(texto), findsOneWidget);
      expect(find.text(Textos.sinAvisos), findsOneWidget);
      await tocar(tester, find.byKey(PantallaMoca.claveEscuchar));
      expect(_loQueDijo, [texto]);
    });

    testWidgets('Sin voz en español, lo dice', (tester) async {
      await abrirApp(tester, listo: true);
      _hayVoz = false;
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      await tocar(tester, find.byKey(PantallaMoca.claveEscuchar));
      expect(find.text(Textos.sinVozEnEspanol), findsOneWidget);
    });

    testWidgets('Un gasto atípico avisa en Moca y en el Inicio', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        var minuto = 0;
        final repo = RepositorioMovimientosLocal(
          base,
          ahora: () => DateTime(2026, 10, 12, 20, minuto++),
        );
        final mercaderia = (await repo.categorias(TipoMovimiento.egreso))
            .firstWhere((c) => c.nombre == 'Mercadería')
            .id;
        for (final soles in [100, 100, 100, 300]) {
          await repo.registrar(
            NuevoMovimiento(
              tipo: TipoMovimiento.egreso,
              montoCentimos: soles * 100,
              cuenta: TipoCuenta.efectivo,
              categoriaId: mercaderia,
            ),
          );
        }
      });
      final texto = Textos.avisoAtipico('S/ 300', 'Mercadería');

      await abrirAjusteOculto(tester);
      await tocarEnAjuste(tester, Textos.saltarPrimeraSemana);
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));
      expect(find.text('$texto.'), findsOneWidget);
      expect(find.text(Textos.verElGasto), findsOneWidget);

      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(texto), findsOneWidget);
      expect(find.text(Textos.paraTenerEnCuenta), findsOneWidget);
      await tocar(tester, find.text(texto));
      expect(find.text(Textos.tituloDetalle), findsOneWidget);
      await tocar(tester, find.byType(BotonVolver));

      await tocar(tester, find.text(Textos.entendido));
      expect(find.text(texto), findsNothing);
      expect(find.text(Textos.sinAvisos), findsOneWidget);
    });

    testWidgets('Informe y Moca no se desbordan con letra grande', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaInformes).last);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await esperar(tester);
      expect(tester.takeException(), isNull, reason: 'S14');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await esperar(tester);
      await tocar(tester, find.text(Textos.verAnio));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await esperar(tester);
      expect(tester.takeException(), isNull, reason: 'el año');
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(tester.takeException(), isNull, reason: 'S16');
    });
  });

  group('Entrega 9', () {
    /// La Demo tarda unos segundos en armarse.
    Future<void> esperarHasta(WidgetTester tester, Finder f) async {
      for (var i = 0; i < 100 && f.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      await esperar(tester);
    }

    testWidgets('«Ver una demo» carga la bodega y «Salir» la borra', (
      tester,
    ) async {
      await abrirApp(tester);
      await tocar(tester, find.text(Textos.verDemo));
      await esperarHasta(tester, find.text(Textos.estasViendoUnaDemo));
      expect(find.text(Textos.estasViendoUnaDemo), findsOneWidget);
      expect(find.text('Bodega Don Lucho'), findsOneWidget);
      expect(find.text(Textos.tienesHoy), findsOneWidget);
      // En la Demo no se pide el permiso de avisos ni se programa nada.
      expect(find.text(Textos.permitirAvisos), findsNothing);
      expect(_programado, isEmpty);

      await tocar(tester, find.text(Textos.salir));
      expect(find.text(Textos.salirDeLaDemoTitulo), findsOneWidget);
      await tocar(tester, find.text(Textos.salir).last);
      expect(find.text(Textos.anotarPrimeraVenta), findsOneWidget);
      expect(find.text(Textos.estasViendoUnaDemo), findsNothing);
    });

    testWidgets('La primera vez pide el permiso de avisos', (tester) async {
      await abrirApp(tester, listo: true, permisoPreguntado: false);
      expect(find.text(Textos.permisoAvisos), findsOneWidget);
      await tocar(tester, find.text(Textos.permitirAvisos));
      expect(find.text(Textos.permisoAvisos), findsNothing);
    });

    testWidgets('Sin permiso, lo explica y no vuelve a pedirlo', (
      tester,
    ) async {
      await abrirApp(tester, listo: true, permisoPreguntado: false);
      _daPermiso = false;
      await tocar(tester, find.text(Textos.permitirAvisos));
      expect(find.text(Textos.sinPermisoAvisos), findsOneWidget);
      await tocar(tester, find.text(Textos.entendido));
      expect(find.text(Textos.sinPermisoAvisos), findsNothing);
    });

    testWidgets('Programa el aviso de cierre de mañana y abre lo que se toca', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      // Hoy ya hay venta: el primer aviso de cierre es mañana.
      final cierres = _programado.where(
        (n) => n.tipo == TipoNotificacion.cierre,
      );
      expect(cierres.first.cuando, DateTime(2026, 10, 13, 21));

      _abrirDesdeAviso!(DestinoNotificacion.arqueo);
      await esperar(tester);
      expect(find.text(Textos.arqueoDeLaSemana), findsOneWidget);
    });
  });

  group('Entrega 9.1', () {
    testWidgets('El ajuste oculto prueba el aviso y muestra los programados', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.probarAvisoCierre));
      expect(_avisosDePrueba, 1);
      expect(find.text(Textos.avisoDePruebaEnviado), findsOneWidget);

      await tocar(tester, find.text(Textos.verAvisosProgramados));
      expect(find.textContaining(Textos.guardadosAlAbrir(0)), findsOneWidget);
      expect(
        find.textContaining('Aviso de cierre · martes 13 de octubre'),
        findsOneWidget,
      );
    });
  });

  group('Entrega 9.2', () {
    testWidgets('El alta ofrece otras billeteras y la otra pide su nombre', (
      tester,
    ) async {
      final base = await abrirApp(tester);
      await abrirVentaEscrita(tester);
      await tester.enterText(find.byType(TextField).at(0), '350');
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tocar(tester, find.text(Textos.ahoraNo));

      await tester.enterText(find.byType(TextField).at(0), 'Bodega Don Lucho');
      await tocar(
        tester,
        find.text(Textos.nombreTipoNegocio(TipoNegocio.bodega)),
      );
      await tocar(tester, find.text(Textos.plin));
      await tocar(tester, find.text(Textos.otra));
      // Sin el nombre de la otra billetera no se puede terminar.
      final listo = find.widgetWithText(FilledButton, Textos.listoEmpezar);
      expect(tester.widget<FilledButton>(listo).onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('nombre-otra-billetera')),
        'Bim',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(listo).onPressed, isNotNull);
      // Cada billetera tiene su saldo.
      expect(find.text(Textos.plin), findsNWidgets(2));
      // El campo del nombre y la fila del saldo.
      expect(find.text('Bim'), findsNWidgets(2));
      await tocar(tester, listo);

      final cuentas = await tester.runAsync(
        () => base.select(base.cuentas).get(),
      );
      expect(
        {for (final c in cuentas!) c.tipo: c.nombre},
        {
          TipoCuenta.efectivo: 'Efectivo',
          TipoCuenta.yape: 'BCP Yape',
          TipoCuenta.banco: 'BCP',
          TipoCuenta.plin: 'Interbank Plin',
          TipoCuenta.otra: 'Bim',
        },
      );

      // En el Inicio completo, las cinco cuentas van en una fila que se
      // desliza (mejora 01).
      await abrirAjusteOculto(tester);
      await tocarEnAjuste(tester, Textos.saltarPrimeraSemana);
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaInicio));
      final efectivo = tester.getTopLeft(find.text(Textos.efectivo));
      final plin = tester.getTopLeft(find.text(Textos.plin));
      final bim = tester.getTopLeft(find.text('Bim'));
      expect(plin.dy, efectivo.dy);
      expect(bim.dy, efectivo.dy);
      expect(bim.dx, greaterThan(plin.dx));
    });

    testWidgets('«Mis cuentas» agrega una billetera que aparece al anotar', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirAjustes(tester);
      await tocar(tester, find.text(Textos.misCuentas));
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('S/\u00A01,350'), findsOneWidget);

      final agregar = find.widgetWithText(FilledButton, Textos.agregar);
      expect(tester.widget<FilledButton>(agregar).onPressed, isNull);
      await tocar(tester, find.text(Textos.sip));
      await tocar(tester, agregar);
      expect(find.text(Textos.billeteraAgregada('Sip')), findsOneWidget);
      // Ya no se ofrece de nuevo; queda en la lista con S/ 0.
      expect(find.text(Textos.sip), findsOneWidget);
      expect(find.text('S/\u00A00'), findsWidgets);

      await tocar(tester, find.byType(BotonVolver));
      // De «Ajustes» a la pestaña Moca.
      await tocar(tester, find.byType(BotonVolver));
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      // Las cuentas aparecen al elegir qué fue (mejora 01).
      await tocar(tester, find.text(Textos.salio));
      expect(find.text(Textos.sip), findsOneWidget);
      expect(find.text(Textos.plin), findsNothing);
    });

    testWidgets('Entrega 16.2: corregir el saldo con el que empezó', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirAjustes(tester);
      await tocar(tester, find.text(Textos.misCuentas));
      await tocar(tester, find.text('Efectivo'));
      expect(find.text(Textos.corregirSaldoInicial), findsOneWidget);
      final guardar = find.widgetWithText(FilledButton, Textos.guardar);
      // Sin cambiar nada no hay qué guardar.
      expect(tester.widget<FilledButton>(guardar).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '800');
      await tester.pump();
      expect(
        find.text(Textos.conEsteCambioTienes('S/\u00A01,150', 'Efectivo')),
        findsOneWidget,
      );
      await tocar(tester, guardar);
      expect(
        find.text(Textos.saldoInicialCorregido('Efectivo')),
        findsOneWidget,
      );
      expect(find.text('S/\u00A01,150'), findsOneWidget);
    });

    testWidgets('Entrega 14.1: «Mis cuentas» agrega un banco con su nombre '
        'y aparece al anotar', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirAjustes(tester);
      await tocar(tester, find.text(Textos.misCuentas));
      expect(find.text(Textos.banco), findsOneWidget);
      expect(find.text(Textos.agregarUnBanco), findsOneWidget);

      final agregar = find.widgetWithText(FilledButton, Textos.agregar);
      await tocar(tester, find.text(Textos.otroBanco));
      // Sin nombre no se puede agregar.
      expect(tester.widget<FilledButton>(agregar).onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('nombre-otro-banco')),
        'Caja Maynas',
      );
      await tester.pump();
      await tocar(tester, agregar);
      expect(
        find.text(Textos.billeteraAgregada('Caja Maynas')),
        findsOneWidget,
      );
      expect(find.text('Caja Maynas'), findsOneWidget);

      await tocar(tester, find.byType(BotonVolver));
      // De «Ajustes» a la pestaña Moca.
      await tocar(tester, find.byType(BotonVolver));
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      // Las cuentas aparecen al elegir qué fue (mejora 01).
      await tocar(tester, find.text(Textos.salio));
      expect(find.text('Caja Maynas'), findsOneWidget);
      expect(find.text(Textos.banco), findsOneWidget);
    });

    testWidgets('«Mis cuentas» no se desborda con letra grande', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrirAjustes(tester);
      await tester.scrollUntilVisible(
        find.text(Textos.misCuentas),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.misCuentas));
      await tocar(tester, find.text(Textos.otra));
      expect(tester.takeException(), isNull);
    });
  });

  group('Entrega 11', () {
    /// Desde la Bienvenida hasta la pantalla del código.
    Future<void> hastaElCodigo(WidgetTester tester) async {
      await abrirVentaEscrita(tester);
      await tester.enterText(find.byType(TextField).at(0), '350');
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.enterText(find.byType(TextField), '987654321');
      await tester.pump();
    }

    Finder enviar() => find.widgetWithText(FilledButton, Textos.enviarmeCodigo);

    testWidgets('Sin señal o con muchos pedidos, el código no se envía', (
      tester,
    ) async {
      await abrirApp(tester);
      await hastaElCodigo(tester);
      _conSenal = false;
      await tocar(tester, enviar());
      expect(find.text(Textos.necesitasSenalParaGuardar), findsOneWidget);
      expect(_servidor.codigosPedidos, isEmpty);

      _conSenal = true;
      _servidor.estadoAlPedir = 429;
      await tocar(tester, enviar());
      expect(find.text(Textos.demasiadosCodigos), findsOneWidget);
      expect(find.text(Textos.escribeElCodigo), findsNothing);
    });

    testWidgets('Un código vencido se reemplaza solo y se puede reenviar', (
      tester,
    ) async {
      await abrirApp(tester);
      await hastaElCodigo(tester);
      await tocar(tester, enviar());
      expect(find.text(Textos.reenviarEn(30)), findsOneWidget);

      await tester.enterText(find.byType(TextField), '000000');
      await esperar(tester);
      expect(find.text(Textos.codigoVencido), findsOneWidget);
      expect(_servidor.codigosPedidos, hasLength(2));

      // A los 30 segundos se puede pedir otro.
      await tester.pump(const Duration(minutes: 6));
      await tocar(tester, find.text(Textos.reenviarCodigo));
      expect(find.text(Textos.codigoReenviado), findsOneWidget);
      expect(_servidor.codigosPedidos, hasLength(3));
    });

    /// Hasta las opciones de un número que ya tiene cuenta (entrega 14.4).
    Future<BaseLocal> hastaLaCuentaExistente(WidgetTester tester) async {
      final base = await abrirApp(tester);
      await hastaElCodigo(tester);
      await tocar(tester, enviar());
      _servidor
        ..cuentaExistente = true
        ..cuentaParaEntrar = _cuentaDeLucho();
      await tester.enterText(find.byType(TextField), '123456');
      await esperar(tester);
      expect(find.text(Textos.numeroConCuenta), findsOneWidget);
      expect(find.text(Textos.entrarAMiCuenta), findsOneWidget);
      expect(find.text(Textos.empezarDeCero), findsOneWidget);
      expect(find.text(Textos.seguirSinCuenta), findsOneWidget);
      // Nada se sube ni se guarda hasta que elija.
      expect(_servidor.subidas, isEmpty);
      expect(await _llavero.leer(), isNull);
      return base;
    }

    testWidgets('Número con cuenta: «Entrar a mi cuenta» suma lo anotado', (
      tester,
    ) async {
      final base = await hastaLaCuentaExistente(tester);
      await tocar(tester, find.text(Textos.entrarAMiCuenta));
      expect(find.text(Textos.yaEstanJuntos), findsOneWidget);
      expect(_servidor.conPase, ['entrar']);
      expect(await _llavero.leer(), 'llave-de-prueba');

      final movimientos = (await tester.runAsync(
        () => base.select(base.movimientos).get(),
      ))!;
      final cuenta = _cuentaDeLucho();
      final empresa = (cuenta['empresa']! as Map)['id'];
      final usuario = (cuenta['usuario']! as Map)['id'];
      // La venta de la cuenta y la de este teléfono, en la misma empresa.
      expect(movimientos, hasLength(2));
      expect(movimientos.map((m) => m.empresaId).toSet(), {empresa});
      expect(movimientos.map((m) => m.autorId).toSet(), {usuario});
      expect(
        movimientos.where(
          (m) => m.estadoSincronizacion == EstadoSincronizacion.porSubir,
        ),
        hasLength(1),
      );
      // Las cuentas de dinero no se duplican.
      final cuentas = (await tester.runAsync(
        () => base.select(base.cuentas).get(),
      ))!;
      expect(cuentas.where((c) => c.tipo == TipoCuenta.efectivo), hasLength(1));
    });

    testWidgets('Número con cuenta: «Empezar de cero» pregunta y sigue como '
        'cuenta nueva', (tester) async {
      await hastaLaCuentaExistente(tester);
      await tocar(tester, find.text(Textos.empezarDeCero));
      expect(find.text(Textos.empezarDeCeroPregunta), findsOneWidget);
      await tocar(tester, find.text(Textos.cancelar));
      expect(_servidor.conPase, isEmpty);

      await tocar(tester, find.text(Textos.empezarDeCero));
      await tocar(tester, find.text(Textos.empezarDeCeroSi));
      expect(_servidor.conPase, ['empezar_de_cero']);
      expect(await _llavero.leer(), 'llave-de-prueba');
      // Del primer día pasa al alta, como cualquier cuenta nueva.
      expect(find.text(Textos.cuentaleDeTuNegocio), findsOneWidget);
    });

    testWidgets('Entrega 14.4.1: si la cuenta del número ya no tiene '
        'negocio, guarda lo de este teléfono sin preguntar', (tester) async {
      await abrirApp(tester);
      await hastaElCodigo(tester);
      await tocar(tester, enviar());
      _servidor
        ..cuentaExistente = true
        ..cuentaSinNegocio = true;
      await tester.enterText(find.byType(TextField), '123456');
      await esperar(tester);
      expect(find.text(Textos.numeroConCuenta), findsNothing);
      expect(_servidor.conPase, ['empezar_de_cero']);
      expect(await _llavero.leer(), 'llave-de-prueba');
      expect(find.text(Textos.cuentaleDeTuNegocio), findsOneWidget);
    });

    testWidgets('Entrega 14.4.1: un error del servidor no se muestra como '
        'falta de señal', (tester) async {
      await hastaLaCuentaExistente(tester);
      // El servidor responde sin datos.
      _servidor.cuentaParaEntrar = null;
      await tocar(tester, find.text(Textos.entrarAMiCuenta));
      expect(find.text(Textos.noPudimosTraerTuCuenta), findsOneWidget);
      expect(find.text(Textos.seCortoLaSenal), findsNothing);

      // Si de verdad se corta, sí lo dice.
      _servidor.cortarBajada = true;
      await tocar(tester, find.text(Textos.intentarOtraVez));
      expect(find.text(Textos.seCortoLaSenal), findsOneWidget);
    });

    testWidgets('Número con cuenta: «Seguir sin cuenta» no guarda nada', (
      tester,
    ) async {
      await hastaLaCuentaExistente(tester);
      await tocar(tester, find.text(Textos.seguirSinCuenta));
      expect(_servidor.conPase, isEmpty);
      expect(await _llavero.leer(), isNull);
      expect(find.text(Textos.cuentaleDeTuNegocio), findsOneWidget);
    });

    testWidgets('A los tres días de «Ahora no», Moca pide guardar el avance', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(Textos.guardarMiAvance), findsNothing);

      _ahora = _ahora.add(const Duration(days: 3));
      await tester.runAsync(() async => base.markTablesUpdated(base.allTables));
      await esperar(tester);
      await tocar(tester, find.text(Textos.guardarMiAvance));
      await tester.enterText(find.byType(TextField), '987654321');
      await tester.pump();
      await tocar(tester, enviar());
      await tester.enterText(find.byType(TextField), '123456');
      await esperar(tester);

      // Vuelve a Moca, sin la tarjeta, y lo anotado ya está en el servidor.
      expect(find.text(Textos.avanceGuardado), findsOneWidget);
      // La pestaña quedó más abajo, donde estaba la tarjeta: sube hasta el
      // título.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await esperar(tester);
      expect(find.text(Textos.eslogan), findsOneWidget);
      expect(find.text(Textos.guardarMiAvance), findsNothing);
      expect(_servidor.subidas, hasLength(1));
      expect(
        (_servidor.subidas.single['empresa']! as Map)['nombre'],
        'Bodega Don Lucho',
      );
    });

    testWidgets('Quien usó el código de prueba confirma su número', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(
        () => base
            .update(base.usuarios)
            .write(const UsuariosCompanion(celular: Value('912345678'))),
      );
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(Textos.confirmaTuNumero), findsOneWidget);
      await tocar(tester, find.text(Textos.confirmarMiNumero));
      expect(find.text('912 345 678'), findsOneWidget);
    });

    testWidgets('Con cuenta, lo anotado se sube solo', (tester) async {
      final base = await abrirApp(tester, listo: true);
      _ahora = _ahora.add(const Duration(days: 3));
      await tester.runAsync(() async => base.markTablesUpdated(base.allTables));
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      await tocar(tester, find.text(Textos.guardarMiAvance));
      await tester.enterText(find.byType(TextField), '987654321');
      await tester.pump();
      await tocar(tester, enviar());
      await tester.enterText(find.byType(TextField), '123456');
      await esperar(tester);
      // El cambio de celular queda en la bitácora y también se sube; después
      // no hay más subidas si nada cambia.
      await tester.pump(const Duration(seconds: 6));
      await esperar(tester);
      final antes = _servidor.subidas.length;
      await tester.pump(const Duration(seconds: 20));
      await esperar(tester);
      expect(_servidor.subidas, hasLength(antes));

      // Un gasto nuevo se sube unos segundos después.
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      await tocar(tester, find.text(Textos.salio));
      await tester.enterText(find.byType(TextField).first, '80');
      await tester.pump();
      await tocar(tester, find.text(Textos.efectivo));
      // Nombre corto, detrás de «Ver más» (mejora 01).
      await tocar(tester, find.text(Textos.verMas));
      await tocar(tester, find.text('Movilidad'));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.pump(const Duration(seconds: 6));
      await esperar(tester);
      expect(_servidor.subidas, hasLength(antes + 1));
      expect([
        for (final m in _servidor.subidas.last['movimientos']! as List)
          (m as Map)['monto_centimos'],
      ], contains(8000));
    });
  });

  group('Entrega 12', () {
    Future<void> entrar(WidgetTester tester) async {
      await tocar(tester, find.text(Textos.yaTengoCuenta));
      await tester.enterText(find.byType(TextField), '987654321');
      await tester.pump();
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.enviarmeCodigo),
      );
      await tester.enterText(find.byType(TextField), '123456');
      await esperar(tester);
    }

    testWidgets('«Ya tengo cuenta» baja todo y abre el Inicio', (tester) async {
      final base = await abrirApp(tester);
      _servidor.cuentaParaEntrar = _cuentaDeLucho();
      await entrar(tester);

      expect(find.text(Textos.yaTienesTodo), findsOneWidget);
      expect(find.text('Bodega Don Lucho'), findsOneWidget);
      expect(find.byType(BarraInferior), findsOneWidget);
      // S/ 1,000 al empezar más la venta de S/ 350.
      expect(find.text('S/\u00A01,350'), findsWidgets);

      final movimientos = await tester.runAsync(
        () => base.select(base.movimientos).get(),
      );
      expect(
        movimientos!.single.estadoSincronizacion,
        EstadoSincronizacion.subido,
      );
      // Lo que bajó no se vuelve a subir.
      await tester.pump(const Duration(seconds: 6));
      await esperar(tester);
      expect(_servidor.subidas, isEmpty);
      expect(await _llavero.leer(), 'llave-de-prueba');
    });

    testWidgets(
      'Entrega 48: un tipo de negocio que no conoce se lee como «Otro»',
      (tester) async {
        final base = await abrirApp(tester);
        final cuenta = _cuentaDeLucho();
        _servidor.cuentaParaEntrar = {
          ...cuenta,
          'empresa': {
            ...cuenta['empresa']! as Map<String, Object?>,
            'tipo_negocio': 'joyeria',
          },
        };
        await entrar(tester);
        expect(find.text(Textos.yaTienesTodo), findsOneWidget);
        final empresa = await tester.runAsync(
          () => base.select(base.empresas).getSingle(),
        );
        expect(empresa!.tipoNegocio, TipoNegocio.otro);
      },
    );

    testWidgets('Si se corta la señal al bajar, se intenta otra vez', (
      tester,
    ) async {
      await abrirApp(tester);
      _servidor
        ..cuentaParaEntrar = _cuentaDeLucho()
        ..cortarBajada = true;
      await entrar(tester);
      expect(find.text(Textos.seCortoLaSenal), findsOneWidget);
      await tocar(tester, find.text(Textos.intentarOtraVez));
      expect(find.text(Textos.yaTienesTodo), findsOneWidget);
      expect(find.text('Bodega Don Lucho'), findsOneWidget);
    });

    testWidgets('Si la cuenta se abrió en otro teléfono, lo dice y no sube', (
      tester,
    ) async {
      final base = await abrirApp(tester);
      _servidor.cuentaParaEntrar = _cuentaDeLucho();
      await entrar(tester);

      // Otro teléfono entra a la cuenta: la llave de este deja de servir.
      _servidor.sesionRevocada = true;
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      await tocar(tester, find.text(Textos.entro));
      await tester.enterText(find.byType(TextField).first, '80');
      await tester.pump();
      await tocar(tester, find.text(Textos.efectivo));
      await tocar(tester, find.text('Venta del día'));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.pump(const Duration(seconds: 6));
      await esperar(tester);
      expect(_servidor.subidas, isEmpty);

      // Entrega 37: por seguridad se borró lo del negocio y solo queda qué
      // pasó, con volver a entrar.
      expect(find.text(Textos.cuentaAbiertaEnOtro), findsOneWidget);
      expect(find.text(Textos.volverAEntrarConMiNumero), findsOneWidget);
      expect(find.text(Textos.tienesHoy), findsNothing);
      expect(find.text(Textos.pestanaMoca), findsNothing);
      // Ya no intenta subir.
      await tester.runAsync(() async => base.markTablesUpdated(base.allTables));
      await tester.pump(const Duration(seconds: 6));
      await esperar(tester);
      expect(_servidor.subidas, isEmpty);
      // Volver a entrar empieza de cero y lleva a entrar con el número.
      await tocar(tester, find.text(Textos.volverAEntrarConMiNumero));
      expect(find.text(Textos.cuentaAbiertaEnOtro), findsNothing);
    });
  });

  group('Entrega 14.6: videos de ayuda', () {
    const enlace = 'https://youtu.be/';
    final todos = {
      for (final v in VideoTutoria.values) v: '$enlace${v.numero}',
    };

    testWidgets('Sin enlaces no aparece ningún video', (tester) async {
      await abrirApp(tester, listo: true);
      expect(find.text(Textos.tusPrimerosPasos), findsOneWidget);
      expect(find.textContaining('Ver cómo'), findsNothing);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(Textos.aprendeEnTresMinutos), findsNothing);
      await tocar(tester, find.text(Textos.pestanaInformes));
      expect(find.text(Textos.verVideo), findsNothing);
    });

    testWidgets('«Ver cómo» en los pasos que faltan; el visto lleva su ✓ en '
        '«Aprende en 3 minutos»', (tester) async {
      final base = await abrirApp(tester, listo: true);
      _enlaces = todos;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MocaApp)),
      );
      container.invalidate(enlacesDeVideosProvider);
      await esperar(tester);

      // El paso 1 ya está hecho: sin video. Los pasos 2, 3 y 4, con el suyo.
      expect(find.text(Textos.verComo(30)), findsOneWidget);
      expect(find.text(Textos.verComo(20)), findsOneWidget);
      expect(find.text(Textos.verComo(25)), findsOneWidget);
      await tocar(tester, find.text(Textos.verComo(20)));
      expect(_abiertos, ['${enlace}2']);

      final eventos = await tester.runAsync(
        () => (base.select(
          base.eventosMedicion,
        )..where((e) => e.nombre.equals('videoAbierto'))).get(),
      );
      expect(eventos!.single.datos, '{"video":2,"desde":"pasos"}');

      await tocar(tester, find.text(Textos.pestanaMoca).last);
      await tester.scrollUntilVisible(
        find.text(Textos.tituloVideo(VideoTutoria.guardarAvance)),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(Textos.aprendeEnTresMinutos), findsOneWidget);
      Matcher visto(bool si) => isSemantics(isChecked: si);
      SemanticsNode fila(VideoTutoria v) =>
          tester.getSemantics(find.text(Textos.tituloVideo(v)));
      expect(fila(VideoTutoria.ventaDelDia), visto(true));
      expect(fila(VideoTutoria.informe), visto(false));
      await tocar(tester, find.text(Textos.tituloVideo(VideoTutoria.informe)));
      expect(_abiertos.last, '${enlace}6');
      expect(fila(VideoTutoria.informe), visto(true));
    });

    testWidgets('«¿Primera vez?» sale una sola vez', (tester) async {
      await abrirApp(tester, listo: true);
      _enlaces = todos;
      ProviderScope.containerOf(tester.element(find.byType(MocaApp)))
          .invalidate(enlacesDeVideosProvider);
      await tocar(tester, find.text(Textos.pestanaInformes));
      expect(find.text(Textos.primeraVez(25)), findsOneWidget);
      await tocar(tester, find.text(Textos.ahoraNoCorto));
      expect(find.text(Textos.primeraVez(25)), findsNothing);
      expect(_abiertos, isEmpty);

      // En Registrar, la del gasto con foto; «Ver video» también la cierra.
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      expect(find.text(Textos.primeraVez(25)), findsOneWidget);
      await tocar(tester, find.text(Textos.verVideo));
      expect(_abiertos, ['${enlace}3']);
      expect(find.text(Textos.primeraVez(25)), findsNothing);
    });

    testWidgets('Si el video no se abre, lo dice y no lo marca', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      _enlaces = todos;
      _abreVideos = false;
      ProviderScope.containerOf(tester.element(find.byType(MocaApp)))
          .invalidate(enlacesDeVideosProvider);
      await esperar(tester);
      await tocar(tester, find.text(Textos.verComo(20)));
      expect(find.text(Textos.videoNoSeAbrio), findsOneWidget);
      expect(find.text(Textos.verComo(20)), findsOneWidget);
      await tocar(tester, find.text(Textos.pestanaInformes));
      expect(find.text(Textos.primeraVez(25)), findsOneWidget);
    });

    testWidgets('El ajuste oculto muestra los videos sin enlace', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.videosSinEnlace));
      expect(find.text(Textos.videosSinEnlaceActivado), findsOneWidget);
      await tocar(
        tester,
        find.byTooltip(
          MaterialLocalizations.of(tester.element(find.byType(Scaffold).last))
              .backButtonTooltip,
        ),
      );
      await tester.scrollUntilVisible(
        find.text(Textos.aprendeEnTresMinutos),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.tituloVideo(VideoTutoria.arqueo)));
      expect(find.text(Textos.videoSinEnlace), findsOneWidget);
      expect(_abiertos, isEmpty);
    });
  });

  group('Entrega 14.7: el código se lee del SMS', () {
    testWidgets('El SMS llega y el código se escribe y comprueba solo', (
      tester,
    ) async {
      final base = await abrirApp(tester);
      _marcaSms = 'Ab3dE5fGh7J';
      await abrirVentaEscrita(tester);
      await tester.enterText(find.byType(TextField).at(0), '350');
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.enterText(find.byType(TextField), '987654321');
      await tester.pump();
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.enviarmeCodigo),
      );

      // Escucha antes de pedirlo y manda la marca para el final del SMS.
      expect(_esperandoSms, 1);
      expect(_servidor.marcasPedidas, ['Ab3dE5fGh7J']);
      expect(find.text(Textos.esperandoSms), findsOneWidget);

      _sms.add('123456');
      await esperar(tester);
      // Comprobado sin tocar nada: sigue al alta.
      expect(find.text(Textos.cuentaleDeTuNegocio), findsOneWidget);
      final eventos = await tester.runAsync(
        () => (base.select(
          base.eventosMedicion,
        )..where((e) => e.nombre.equals('codigoComprobado'))).get(),
      );
      expect(eventos!.single.datos, '{"delSms":true}');
    });

    testWidgets('Sin lectura del SMS, se escribe como siempre', (tester) async {
      await abrirApp(tester);
      await abrirVentaEscrita(tester);
      await tester.enterText(find.byType(TextField).at(0), '350');
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await tester.enterText(find.byType(TextField), '987654321');
      await tester.pump();
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.enviarmeCodigo),
      );
      expect(_esperandoSms, 0);
      expect(_servidor.marcasPedidas, [null]);
      expect(find.text(Textos.esperandoSms), findsNothing);
      await tester.enterText(find.byType(TextField), '123456');
      await esperar(tester);
      expect(find.text(Textos.cuentaleDeTuNegocio), findsOneWidget);
    });
  });

  group('Entrega 19: Mi equipo y «Me invitaron»', () {
    Future<void> alCodigoDeInvitado(WidgetTester tester) async {
      await tocar(tester, find.text(Textos.meInvitaron));
      expect(find.text(Textos.entraAlNegocioDetalle), findsOneWidget);
      await tester.enterText(find.byType(TextField), '987000003');
      await tester.pump();
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.enviarmeCodigo),
      );
      await tester.enterText(find.byType(TextField), '123456');
      await esperar(tester);
    }

    testWidgets('La Bienvenida cabe en un teléfono pequeño', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await abrirApp(tester);
      expect(find.text(Textos.meInvitaron), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sin invitación, lo dice y no entra', (tester) async {
      await abrirApp(tester);
      await alCodigoDeInvitado(tester);
      expect(find.text(Textos.sinInvitacion), findsOneWidget);
      expect(_servidor.aceptadas, isEmpty);
    });

    testWidgets('El invitado ve a qué negocio y con qué rol, acepta y entra', (
      tester,
    ) async {
      await abrirApp(tester);
      _servidor
        ..invitacionesRecibidas = [
          {
            'id': 'inv-1',
            'negocio': 'Bodega Don Lucho',
            'rol': 'ayudante',
            'nombre': 'Pepe',
            'vence_en': _ahora
                .add(const Duration(days: 7))
                .toUtc()
                .toIso8601String(),
          },
        ]
        ..cuentaParaEntrar = {
          ..._cuentaDeLucho(),
          'membresia': {
            ...(_cuentaDeLucho()['membresia']! as Map),
            'rol': 'ayudante',
          },
        };
      await alCodigoDeInvitado(tester);
      expect(find.text(Textos.teInvitaron('Bodega Don Lucho')), findsOneWidget);
      expect(find.text(Textos.comoRol('Ayudante')), findsOneWidget);
      expect(find.text(Textos.detalleRol(Rol.ayudante)), findsOneWidget);
      expect(find.text(Textos.consentimientoInvitado), findsOneWidget);

      await tocar(tester, find.text(Textos.aceptarYEntrar));
      expect(_servidor.aceptadas, ['inv-1']);
      expect(find.text(Textos.yaEstasEn('Bodega Don Lucho')), findsOneWidget);
      expect(find.text('Bodega Don Lucho'), findsWidgets);
    });

    Future<BaseLocal> conCuentaGuardada(WidgetTester tester) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        await _llavero.guardar('llave-de-prueba');
        await AccesoLocal(
          base,
          () => _ahora,
        ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321');
      });
      await esperar(tester);
      return base;
    }

    Map<String, Object?> equipoDeLucho() => {
      'rol': 'dueno',
      'titular': true,
      'maximo': 3,
      'personas': [
        {
          'membresia_id': 'm-lucho',
          'usuario_id': 'u-lucho',
          'nombre': null,
          'rol': 'dueno',
          'titular': true,
          'celular': '+51987654321',
        },
        {
          'membresia_id': 'm-rosa',
          'usuario_id': 'u-rosa',
          'nombre': 'Rosa',
          'rol': 'ayudante',
          'titular': false,
          'celular': '+51987000002',
        },
      ],
      'invitaciones': [
        {
          'id': 'inv-pepe',
          'celular': '+51987000003',
          'rol': 'contador',
          'nombre': 'Pepe',
          'vence_en': _ahora
              .add(const Duration(days: 7))
              .toUtc()
              .toIso8601String(),
        },
      ],
    };

    testWidgets('Sin cuenta guardada, «Mi equipo» no aparece', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirAjustes(tester);
      expect(find.text(Textos.miEquipo), findsNothing);
    });

    testWidgets('Entrega 45.1: sin la cuenta unida, entrar o borrar desde '
        'Ajustes', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirAjustes(tester);
      expect(find.text(Textos.entrarConMiCelular), findsOneWidget);
      // «Entrar con mi celular» lleva a poner el número.
      await tocar(tester, find.text(Textos.entrarConMiCelular));
      expect(find.text(Textos.tuNumeroDeCelular), findsWidgets);
      await tocar(tester, find.byType(BotonVolver).first);
      // «Borrar todo» vuelve a la bienvenida, con «Ya tengo cuenta».
      await tocar(tester, find.text(Textos.borrarEsteTelefono));
      expect(find.text(Textos.borrarEsteTelefonoPregunta), findsOneWidget);
      await tocar(tester, find.text(Textos.borrar));
      await esperar(tester);
      expect(find.text(Textos.yaTengoCuenta), findsOneWidget);
    });

    testWidgets('Entrega 46: «Ayuda» sin cuenta, y pedir ayuda por WhatsApp', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await abrirAjustes(tester);
      await tester.scrollUntilVisible(
        find.text(Textos.estadoDeEsteTelefono),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(Textos.sinCuentaAyuda), findsOneWidget);
      // Sin el número de soporte, no hay botón.
      expect(find.text(Textos.pedirAyudaWhatsApp), findsNothing);
      await tester.runAsync(
        () => AccesoLocal(base, () => _ahora).guardarAjuste(
          AccesoLocal.claveVersion,
          jsonEncode({'soporte': '911111111'}),
        ),
      );
      await esperar(tester);
      await tester.scrollUntilVisible(
        find.text(Textos.pedirAyudaWhatsApp),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.pedirAyudaWhatsApp));
      expect(_abiertos.single, startsWith('https://wa.me/51911111111?text='));
      final texto = Uri.parse(_abiertos.single).queryParameters['text']!;
      expect(texto, startsWith('Hola, necesito ayuda con Moca.'));
      expect(texto, contains('Cuenta: ${Textos.sinCuentaAyuda}'));
      expect(texto, contains('Negocio: Bodega Don Lucho (código '));
      expect(texto, contains('Rol: Dueño (titular)'));
    });

    testWidgets(
      'Entrega 46: el estado con cuenta, y abierta en otro teléfono',
      (tester) async {
        final base = await conCuentaGuardada(tester);
        await abrirAjustes(tester);
        await tester.scrollUntilVisible(
          find.text(Textos.estadoDeEsteTelefono),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(Textos.unidoATuCuenta('987 654 321')), findsOneWidget);
        expect(
          find.text(Textos.negocioYRol('Bodega Don Lucho', 'Dueño', true)),
          findsOneWidget,
        );
        // Lo que espera subir se dice, con qué hacer.
        await tester.runAsync(
          () => base
              .update(base.movimientos)
              .write(
                const MovimientosCompanion(
                  estadoSincronizacion: Value(EstadoSincronizacion.porSubir),
                ),
              ),
        );
        await esperar(tester);
        expect(
          find.textContaining('por subir: abre Moca con señal'),
          findsOneWidget,
        );
        await tester.runAsync(
          () => AccesoLocal(
            base,
            () => _ahora,
          ).guardarAjuste('cuenta_cerrada_en_otro', 'si'),
        );
        await esperar(tester);
        expect(find.text(Textos.abiertaEnOtroAyuda), findsOneWidget);
        expect(find.text(Textos.abiertaEnOtroQueHacer), findsOneWidget);
      },
    );

    testWidgets('Entrega 45.1: con la cuenta unida no aparecen', (
      tester,
    ) async {
      await conCuentaGuardada(tester);
      await abrirAjustes(tester);
      expect(find.text(Textos.entrarConMiCelular), findsNothing);
      expect(find.text(Textos.borrarEsteTelefono), findsNothing);
    });

    testWidgets('Entrega 43: invitar a alguien que el plan no incluye', (
      tester,
    ) async {
      final base = await conCuentaGuardada(tester);
      await tester.runAsync(
        () => AccesoLocal(base, () => _ahora).guardarAjuste(
          AccesoLocal.claveCobro,
          jsonEncode({
            'estado': 'pagado',
            'hasta': '2026-12-01',
            'plan': 'basico',
            'nivel': 'basico',
            'incluidas': 1,
            'credito': false,
          }),
        ),
      );
      _servidor.equipo = {...equipoDeLucho(), 'incluidas': 1};
      await abrirAjustes(tester);
      await tocar(tester, find.text(Textos.miEquipo));
      expect(find.text(Textos.planIncluye(1)), findsOneWidget);
      await tocar(tester, find.text(Textos.invitarAAlguien));
      await tester.enterText(find.byType(TextField).at(0), 'Carmen');
      await tester.enterText(find.byType(TextField).at(1), '987000004');
      await tester.pump();
      await tocar(tester, find.text(Textos.enviarInvitacion));
      // Se avisa antes; con «Cancelar» no se invita.
      expect(find.text(Textos.personaExtraDetalle(1)), findsOneWidget);
      await tocar(tester, find.text(Textos.cancelar));
      expect(_servidor.invitados, isEmpty);
      await tocar(tester, find.text(Textos.enviarInvitacion));
      await tocar(tester, find.text(Textos.invitarIgual));
      expect(_servidor.invitados, hasLength(1));
    });

    testWidgets('El dueño ve su equipo, invita y quita', (tester) async {
      await conCuentaGuardada(tester);
      _servidor.equipo = equipoDeLucho();
      await abrirAjustes(tester);
      await tocar(tester, find.text(Textos.miEquipo));
      expect(find.text('Rosa'), findsOneWidget);
      expect(find.text('Ayudante · 987 000 002'), findsOneWidget);
      expect(find.text('Pepe'), findsOneWidget);
      // Sin tope (entrega 43): lo que incluye el plan.
      expect(find.text(Textos.planIncluye(3)), findsOneWidget);

      // Invitar: con ya las 3 personas, lo dice.
      await tocar(tester, find.text(Textos.invitarAAlguien));
      await tester.enterText(find.byType(TextField).at(0), 'Carmen');
      await tester.enterText(find.byType(TextField).at(1), '987000004');
      await tester.pump();
      await tocar(tester, find.text(Textos.nombreRol(Rol.encargado)));
      expect(find.text(Textos.detalleRol(Rol.encargado)), findsOneWidget);
      _servidor.errorAlInvitar = 'sin_lugar';
      await tocar(tester, find.text(Textos.enviarInvitacion));
      expect(find.text(Textos.sinLugar), findsOneWidget);
      _servidor.errorAlInvitar = null;
      await tocar(tester, find.text(Textos.enviarInvitacion));
      expect(_servidor.invitados.single, {
        'celular': '987000004',
        'rol': 'encargado',
        'nombre': 'Carmen',
      });
      expect(find.text(Textos.invitacionEnviada('Carmen')), findsOneWidget);

      // El mensaje por WhatsApp, listo para Carmen (entrega 30).
      await tocar(tester, find.text(Textos.mandarInvitacionWhatsApp));
      expect(_abiertos.single, startsWith('https://wa.me/51987000004?text='));
      expect(_abiertos.single, isNot(contains('+')));
      expect(
        Uri.parse(_abiertos.single).queryParameters['text'],
        Textos.mensajeDeInvitacion(
          nombre: 'Carmen',
          negocio: 'Bodega Don Lucho',
          rol: Rol.encargado,
          celular: '987 000 004',
          vence: formatearDiaYMes(_ahora.add(const Duration(days: 7))),
          enlace: 'https://moca-servidor.onrender.com/descargar',
        ),
      );
      await tocar(tester, find.text(Textos.listoInvitar));

      // La invitación que espera también se manda otra vez.
      _abiertos.clear();
      await tocar(tester, find.text(Textos.mandarPorWhatsApp));
      final texto = Uri.parse(_abiertos.single).queryParameters['text']!;
      expect(_abiertos.single, startsWith('https://wa.me/51987000003?text='));
      expect(texto, startsWith('Hola Pepe, te invité a Bodega Don Lucho'));
      expect(texto, contains('como Contador'));

      // Quitar a Rosa, con confirmación.
      await tocar(tester, find.text(Textos.quitar));
      expect(find.text(Textos.quitarPregunta('Rosa')), findsOneWidget);
      await tocar(tester, find.text(Textos.quitar).last);
      expect(_servidor.quitados, ['m-rosa']);
    });

    testWidgets('Quien no es dueño solo mira', (tester) async {
      await conCuentaGuardada(tester);
      _servidor.equipo = {
        ...equipoDeLucho(),
        'rol': 'ayudante',
        'titular': false,
        'invitaciones': <Object>[],
      };
      await abrirAjustes(tester);
      await tocar(tester, find.text(Textos.miEquipo));
      expect(find.text('Rosa'), findsOneWidget);
      expect(find.text(Textos.quitar), findsNothing);
      expect(find.text(Textos.invitarAAlguien), findsNothing);
      expect(find.text(Textos.mandarPorWhatsApp), findsNothing);
    });

    testWidgets('Sin señal, lo dice', (tester) async {
      await conCuentaGuardada(tester);
      await abrirAjustes(tester);
      _conSenal = false;
      await tocar(tester, find.text(Textos.miEquipo));
      expect(find.text(Textos.necesitasSenalParaEquipo), findsOneWidget);
    });
  });

  group('Entrega 20: cada rol ve lo suyo', () {
    Future<BaseLocal> comoRol(WidgetTester tester, Rol rol) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(
        () => base
            .update(base.membresias)
            .write(MembresiasCompanion(rol: Value(rol))),
      );
      await esperar(tester);
      return base;
    }

    testWidgets('El ayudante anota y ve lo suyo de hoy, sin la plata del '
        'negocio', (tester) async {
      await comoRol(tester, Rol.ayudante);
      expect(find.text(Textos.tienesHoy), findsNothing);
      // Su caja (la principal, sin otra asignada) y lo que vendió hoy.
      expect(find.text(Textos.enTuCaja), findsOneWidget);
      expect(find.textContaining(Textos.hoyAnotaste), findsOneWidget);
      expect(find.text(Textos.hacerArqueo), findsNothing);
      expect(find.text(Textos.pestanaInformes), findsNothing);
      expect(find.bySemanticsLabel(Textos.registrar), findsOneWidget);

      await tocar(tester, find.text(Textos.pestanaHistorial));
      expect(find.text(Textos.soloLoDeHoyAyudante), findsOneWidget);

      await abrirAjustes(tester);
      expect(find.text(Textos.avisos), findsNothing);
      expect(find.text(Textos.misCuentas), findsNothing);
      await tocar(tester, find.byType(BotonVolver));

      // Anota ventas y gastos, no retiros ni aportes.
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      expect(find.text(Textos.entro), findsOneWidget);
      expect(find.text(Textos.retiroParaMi), findsNothing);
      expect(find.text(Textos.puseDeMiBolsillo), findsNothing);
    });

    testWidgets('Entrega 20.2: el ayudante ve lo de hoy en su caja, aunque '
        'lo anote otro', (tester) async {
      final base = await comoRol(tester, Rol.ayudante);
      await tester.runAsync(
        () => RepositorioOperadorLocal(
          base,
          ahora: () => _ahora,
        ).simularVentaDeOtro(),
      );
      await esperar(tester);
      await tocar(tester, find.text(Textos.pestanaHistorial));
      expect(
        find.textContaining(Textos.loAnoto(AccesoLocal.nombreSimulado, null)),
        findsWidgets,
      );
    });

    testWidgets('El contador solo mira', (tester) async {
      await comoRol(tester, Rol.contador);
      expect(find.text(Textos.tienesHoy), findsOneWidget);
      expect(find.bySemanticsLabel(Textos.registrar), findsNothing);
      expect(find.text(Textos.anotarVentaDeHoy), findsNothing);
      expect(find.text(Textos.hacerArqueo), findsNothing);
      expect(find.text(Textos.pestanaInformes), findsOneWidget);

      await tocar(tester, find.text(Textos.pestanaHistorial));
      await tocar(tester, find.text('Venta del día'));
      expect(find.text(Textos.tituloDetalle), findsOneWidget);
      expect(find.text(Textos.corregir), findsNothing);
      expect(find.text(Textos.deshacerRegistro), findsNothing);
    });

    testWidgets('Entrega 45: el contador no recuerda deudas por WhatsApp', (
      tester,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        final repo = RepositorioMovimientosLocal(base, ahora: () => _ahora);
        final ingresos = await repo.categorias(TipoMovimiento.ingreso);
        await repo.registrar(
          NuevoMovimiento(
            tipo: TipoMovimiento.ingreso,
            montoCentimos: 5000,
            cuenta: TipoCuenta.efectivo,
            categoriaId: ingresos.first.id,
            pagado: false,
            contraparte: 'Don Pepe',
          ),
        );
        await base
            .update(base.membresias)
            .write(const MembresiasCompanion(rol: Value(Rol.contador)));
      });
      await esperar(tester);
      await tocar(tester, find.text(Textos.pestanaInformes));
      await tester.scrollUntilVisible(
        find.text(Textos.loQueTeDebenTitulo),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.loQueTeDebenTitulo));
      expect(find.textContaining('Don Pepe'), findsWidgets);
      expect(find.text(Textos.recordarPorWhatsApp), findsNothing);
    });

    testWidgets('El encargado no ve los informes ni cambia las cuentas', (
      tester,
    ) async {
      await comoRol(tester, Rol.encargado);
      expect(find.text(Textos.enTuCaja), findsOneWidget);
      expect(find.text(Textos.hacerArqueo), findsWidgets);
      expect(find.text(Textos.pestanaInformes), findsNothing);
      await abrirAjustes(tester);
      expect(find.text(Textos.misCuentas), findsNothing);
    });
  });

  group('Entrega 21: varias cajas', () {
    testWidgets('El dueño agrega una caja con nombre en «Mis cuentas»', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await abrirAjustes(tester);
      await tocar(tester, find.text(Textos.misCuentas));
      await tocar(tester, find.text(Textos.otraCaja));
      await tester.enterText(
        find.byKey(const Key('nombre-caja')),
        'Caja delivery',
      );
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.agregar));
      expect(find.text('Caja delivery'), findsWidgets);
    });

    testWidgets('El ayudante a cargo de «Caja delivery» ve su caja y anota '
        'en ella, no en la principal', (tester) async {
      final base = await abrirApp(tester, listo: true);
      await abrirAjustes(tester);
      await tocar(tester, find.text(Textos.misCuentas));
      await tocar(tester, find.text(Textos.otraCaja));
      await tester.enterText(
        find.byKey(const Key('nombre-caja')),
        'Caja delivery',
      );
      await tester.pump();
      await tocar(tester, find.widgetWithText(FilledButton, Textos.agregar));
      // Como al bajar del servidor: todo en una transacción.
      await tester.runAsync(
        () => base.transaction(() async {
          final delivery = await (base.select(
            base.cuentas,
          )..where((c) => c.tipo.equalsValue(TipoCuenta.caja2))).getSingle();
          await AccesoLocal(
            base,
            () => _ahora,
          ).guardarAjuste(AccesoLocal.claveMisCajas, jsonEncode([delivery.id]));
          await base
              .update(base.membresias)
              .write(const MembresiasCompanion(rol: Value(Rol.ayudante)));
        }),
      );
      await esperar(tester);
      await tocar(tester, find.byType(BotonVolver).first);
      await tocar(tester, find.byType(BotonVolver).first);
      await tocar(tester, find.text(Textos.pestanaInicio));
      expect(find.text(Textos.enTuCaja), findsOneWidget);

      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      await tocar(tester, find.text(Textos.salio));
      expect(find.text('Caja delivery'), findsOneWidget);
      expect(find.text(Textos.efectivo), findsNothing);
      expect(find.text(Textos.yape), findsOneWidget);
    });
  });

  testWidgets('Entrega 21.1: «Pasé plata» de la caja a Yape sale en el '
      'Historial como una sola fila', (tester) async {
    await abrirApp(tester, listo: true);
    await tocar(tester, find.bySemanticsLabel(Textos.registrar));
    await tocar(tester, find.text(Textos.escribirlo));
    await tocar(tester, find.text(Textos.pasePlata));
    expect(find.text(Textos.pasePlataDetalle), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pump();
    expect(find.text(Textos.deDondeSalePase), findsOneWidget);
    await tocar(tester, find.text(Textos.efectivo));
    await tocar(tester, find.text(Textos.yape).last);
    await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
    await tocar(tester, find.text(Textos.pestanaHistorial));
    expect(find.text(Textos.pasePlata), findsOneWidget);
    expect(
      find.text(Textos.pase(Textos.efectivo, Textos.yape)),
      findsOneWidget,
    );
  });

  group('Entrega 20.1: simular otra persona con un solo teléfono', () {
    testWidgets('«Ver como» muestra la app de otro rol y se vuelve con un '
        'toque', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.verComoRol));
      await tocar(tester, find.text(Textos.nombreRol(Rol.ayudante)));
      expect(
        find.text(Textos.viendoComo(Textos.nombreRol(Rol.ayudante))),
        findsOneWidget,
      );
      expect(find.textContaining(Textos.hoyAnotaste), findsOneWidget);
      expect(find.text(Textos.pestanaInformes), findsNothing);

      await tocar(tester, find.text(Textos.volverADueno));
      expect(find.text(Textos.pestanaInformes), findsOneWidget);
      expect(
        find.text(Textos.viendoComo(Textos.nombreRol(Rol.ayudante))),
        findsNothing,
      );
    });

    testWidgets('La venta de Pepe dice quién la anotó, no se sube y se va al '
        'salir', (tester) async {
      final base = await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.simularVentaDeOtro));
      expect(find.text(Textos.ventaDeOtroSimulada), findsOneWidget);
      await tocar(tester, find.byType(IconButton).first);
      await tocar(tester, find.text(Textos.pestanaHistorial));
      expect(
        find.text('Efectivo · ${Textos.loAnoto('Pepe', null)}'),
        findsOneWidget,
      );

      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.salirDeLaSimulacion));
      final dePepe = await tester.runAsync(
        () => (base.select(
          base.movimientos,
        )..where((m) => m.autorId.equals(AccesoLocal.usuarioSimulado))).get(),
      );
      expect(dePepe, isEmpty);
    });
  });

  group('Entrega 14.8: borrar todo, también en el servidor', () {
    Future<BaseLocal> conCuentaGuardada(WidgetTester tester) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        await _llavero.guardar('llave-de-prueba');
        await AccesoLocal(
          base,
          () => _ahora,
        ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321');
      });
      await esperar(tester);
      return base;
    }

    Future<int> movimientos(WidgetTester tester, BaseLocal base) async =>
        (await tester.runAsync(() => base.select(base.movimientos).get()))!
            .length;

    testWidgets('Sin cuenta guardada no aparece', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      expect(find.text(Textos.borrarTodo), findsOneWidget);
      expect(find.text(Textos.borrarEnServidor), findsNothing);
    });

    testWidgets('Aviso, escribir BORRAR y queda como recién instalada', (
      tester,
    ) async {
      final base = await conCuentaGuardada(tester);
      expect(await movimientos(tester, base), greaterThan(0));
      await abrirAjusteOculto(tester);
      await tocar(tester, find.text(Textos.borrarEnServidor));
      expect(
        find.text(Textos.borrarEnServidorAviso('987 654 321')),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.continuar));

      final boton = find.widgetWithText(TextButton, Textos.borrarParaSiempre);
      expect(tester.widget<TextButton>(boton).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'borra');
      await tester.pump();
      expect(tester.widget<TextButton>(boton).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'BORRAR');
      await tester.pump();
      await tocar(tester, boton);

      expect(_servidor.borrados, ['BORRAR']);
      expect(find.text(Textos.seBorroTodoEnServidor), findsOneWidget);
      expect(find.text(Textos.anotarPrimeraVenta), findsOneWidget);
      expect(await movimientos(tester, base), 0);
    });

    testWidgets('Sin señal no se borra nada, tampoco el teléfono', (
      tester,
    ) async {
      final base = await conCuentaGuardada(tester);
      final antes = await movimientos(tester, base);
      await abrirAjusteOculto(tester);
      _conSenal = false;
      await tocar(tester, find.text(Textos.borrarEnServidor));
      await tocar(tester, find.text(Textos.continuar));
      await tester.enterText(find.byType(TextField), 'BORRAR');
      await tester.pump();
      await tocar(
        tester,
        find.widgetWithText(TextButton, Textos.borrarParaSiempre),
      );
      expect(find.text(Textos.borrarSinSenal), findsOneWidget);
      expect(_servidor.borrados, isEmpty);
      expect(await movimientos(tester, base), antes);
    });
  });

  testWidgets('Entrega 18.1: deslizar hacia abajo en el Historial trae lo '
      'de los demás', (tester) async {
    final base = await abrirApp(tester, listo: true);
    await tester.runAsync(() async {
      await _llavero.guardar('llave-de-prueba');
      await AccesoLocal(
        base,
        () => _ahora,
      ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321');
    });
    await esperar(tester);
    await tocar(tester, find.text(Textos.pestanaHistorial));
    final antes = _servidor.pedidosDeCambios;
    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await esperar(tester);
    expect(_servidor.pedidosDeCambios, greaterThan(antes));
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('Entrega 27: Jhony ve los errores agrupados y copia el detalle', (
    tester,
  ) async {
    await abrirApp(tester, listo: true);
    await tester.runAsync(() => _llavero.guardar('llave-de-prueba'));
    await abrirAjusteOculto(tester);
    await tocar(tester, find.text(Textos.errores));
    expect(find.text('Bad state: se rompió'), findsOneWidget);
    expect(find.textContaining(Textos.erroresVeces(3, 2)), findsOneWidget);
    await tocar(tester, find.text(Textos.copiarDetalle));
    expect(find.text(Textos.detalleCopiado), findsOneWidget);
  });

  group('Entrega 26.3: «Hay una versión nueva de Moca»', () {
    const instalada = VersionInstalada(
      entrega: 'piloto-1',
      armado: 100,
      commit: 'abc1234',
      esArm64: true,
    );
    Map<String, Object?> publicada(int armado, {int? minima}) => {
      'ultima': {
        'nombre': 'piloto-2',
        'armado': armado,
        'arm64': 'https://x/arm64.apk',
        'v7a': 'https://x/v7a.apk',
      },
      'minima': minima,
    };

    Future<void> abrirCon(
      WidgetTester tester,
      Map<String, Object?> version, {
      bool admin = false,
    }) async {
      await abrirApp(
        tester,
        listo: true,
        admin: admin,
        versionInstalada: instalada,
        versionDelServidor: version,
      );
      // La revisión sale después del primer cuadro, y lee lo guardado antes
      // de guardar lo nuevo (entrega 34).
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await esperar(tester);
      }
    }

    testWidgets('Con una más nueva, el Inicio lo dice y descarga el APK', (
      tester,
    ) async {
      await abrirCon(tester, publicada(110));
      expect(find.text(Textos.hayVersionNueva), findsOneWidget);
      // Un piloto solo pregunta por «piloto-N».
      expect(_servidor.canalesPedidos, [null]);
      await tocar(tester, find.text(Textos.descargar));
      expect(_abiertos, ['https://x/arm64.apk']);
    });

    testWidgets('«Ahora no» la esconde hasta mañana', (tester) async {
      await abrirCon(tester, publicada(110));
      await tocar(tester, find.text(Textos.ahoraNoVersion));
      expect(find.text(Textos.hayVersionNueva), findsNothing);
    });

    testWidgets('Si ya es la última, no dice nada; y se ve su versión', (
      tester,
    ) async {
      await abrirCon(tester, publicada(100), admin: true);
      expect(find.text(Textos.hayVersionNueva), findsNothing);
      // Jhony pregunta también por las entregas.
      expect(_servidor.canalesPedidos, ['todas']);
      await abrirAjustes(tester);
      await tester.scrollUntilVisible(
        find.text(Textos.versionDeMoca('piloto-1', 100)),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(Textos.versionDeMoca('piloto-1', 100)), findsOneWidget);
    });

    Future<void> otroDia(WidgetTester tester, BaseLocal base) async {
      _ahora = _ahora.add(const Duration(days: 1));
      await tester.runAsync(() async => base.markTablesUpdated(base.allTables));
      await esperar(tester);
    }

    Future<BaseLocal> baseDe(WidgetTester tester) async =>
        ProviderScope.containerOf(tester.element(find.byType(MocaApp)))
            .read(baseLocalProvider);

    testWidgets(
      'Entrega 34: obligatoria, un día de gracia y luego no se anota',
      (tester) async {
        await abrirCon(tester, publicada(110, minima: 105));
        // El primer día avisa, sin «Ahora no», y se sigue anotando.
        expect(find.text(Textos.actualizaDesdeManana), findsOneWidget);
        expect(find.text(Textos.ahoraNoVersion), findsNothing);
        expect(find.text(Textos.tienesHoy), findsOneWidget);
        await tocar(tester, find.bySemanticsLabel(Textos.registrar));
        expect(find.text(Textos.escribirlo), findsOneWidget);
        // La hoja del + se cierra con «Cancelar» (mejora 01).
        await tocar(tester, find.text(Textos.cancelar));

        // Al día siguiente, lo que anota lleva a actualizar.
        await otroDia(tester, await baseDe(tester));
        expect(find.text(Textos.actualizaParaAnotar), findsOneWidget);
        expect(find.text(Textos.tienesHoy), findsOneWidget);
        await tocar(tester, find.bySemanticsLabel(Textos.registrar));
        expect(find.text(Textos.actualizaMoca), findsOneWidget);
        expect(find.text(Textos.escribirlo), findsNothing);
        await tocar(
          tester,
          find.widgetWithText(FilledButton, Textos.descargar),
        );
        expect(_abiertos.last, 'https://x/arm64.apk');
        // Ver sigue: vuelve y abre el Historial.
        await tocar(tester, find.text(Textos.volver));
        await tocar(tester, find.text(Textos.pestanaHistorial));
        expect(find.text(Textos.actualizaMoca), findsNothing);
        // Sin señal no se bloquea: ver test/dominio_version_test.dart.
      },
    );

    testWidgets('Entrega 34: el teléfono de Jhony nunca se bloquea', (
      tester,
    ) async {
      await abrirCon(tester, publicada(110, minima: 105), admin: true);
      await otroDia(tester, await baseDe(tester));
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      expect(find.text(Textos.escribirlo), findsOneWidget);
    });
  });

  group('Entrega 26.2: el ajuste oculto solo en el teléfono de Jhony', () {
    testWidgets('En otro teléfono, mantener presionado el logo no lo abre', (
      tester,
    ) async {
      await abrirApp(tester, listo: true, admin: false);
      await abrirAjusteOculto(tester);
      expect(find.text(Textos.tituloOperador), findsNothing);
      expect(find.text(Textos.eslogan), findsOneWidget);
    });

    testWidgets('En el de Jhony, sí', (tester) async {
      await abrirApp(tester, listo: true);
      await abrirAjusteOculto(tester);
      expect(find.text(Textos.tituloOperador), findsOneWidget);
    });

    testWidgets('Una simulación que quedó puesta se quita al abrir', (
      tester,
    ) async {
      final base = await abrirApp(
        tester,
        listo: true,
        admin: false,
        verComoAlAbrir: Rol.ayudante,
      );
      await esperar(tester);
      final verComo = await tester.runAsync(
        () => AccesoLocal(
          base,
          () => _ahora,
        ).leerAjuste(AccesoLocal.claveVerComo),
      );
      expect(verComo, isNull);
      // La base avisa del cambio fuera del reloj falso de la prueba.
      await tester.runAsync(() async => base.markTablesUpdated(base.allTables));
      await esperar(tester);
      // De vuelta a la vista del dueño: sin la franja de «Ver como».
      expect(find.text(Textos.hoyAnotaste), findsNothing);
      expect(find.text(Textos.tienesHoy), findsOneWidget);
    });
  });

  group('Entrega 26: la pantalla de cobros de Jhony', () {
    Future<void> comoAdmin(WidgetTester tester, {required bool admin}) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        await _llavero.guardar('llave-de-prueba');
        await AccesoLocal(
          base,
          () => _ahora,
        ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321');
      });
      await esperar(tester);
      await tester.runAsync(
        () => AccesoLocal(base, () => _ahora).guardarAjuste(
          AccesoLocal.claveCobro,
          jsonEncode({'estado': 'sin_cobro', 'admin': admin}),
        ),
      );
      await esperar(tester);
      await abrirAjusteOculto(tester);
    }

    testWidgets('Entrega 47: la ficha de soporte, días de prueba y borrar', (
      tester,
    ) async {
      await comoAdmin(tester, admin: true);
      await tocar(tester, find.text(Textos.cobros));
      await tester.enterText(find.byType(TextField), '987654321');
      await tester.pump();
      await tocar(tester, find.text(Textos.buscar));
      // Las personas con su versión, la invitación y los registros.
      expect(
        find.text(
          Textos.personaSoporte(
            rol: 'dueno',
            titular: true,
            celular: '987 654 321',
            version: 'entrega-47 (180)',
            subio: '12 de octubre',
          ),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          Textos.invitacionSoporte('987 000 002', 'ayudante', 'vencida', null),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(Textos.registrosSoporte(12), skipOffstage: false),
        findsOneWidget,
      );
      // Días de prueba: 7 o 14.
      await tocar(tester, find.text(Textos.darDiasDePrueba));
      await tocar(tester, find.text(Textos.diasDePrueba(7)));
      expect(_servidor.diasDados, [7]);
      await tester.pump(const Duration(seconds: 5));
      await esperar(tester);
      // Borrar, con el nombre del negocio.
      await tocar(tester, find.text(Textos.borrarElNegocio));
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Bodega Don Lucho',
      );
      await tocar(tester, find.text(Textos.borrar));
      expect(find.text(Textos.negocioBorrado47), findsOneWidget);
    });

    testWidgets('Solo aparece en el teléfono de quien registra los pagos', (
      tester,
    ) async {
      await comoAdmin(tester, admin: false);
      expect(find.text(Textos.cobros), findsNothing);
    });

    testWidgets('Buscar por celular, registrar un pago y ver lo que vence', (
      tester,
    ) async {
      await comoAdmin(tester, admin: true);
      await tocar(tester, find.text(Textos.cobros));
      expect(find.text(Textos.fundadoresUsados(0, 50)), findsOneWidget);
      expect(find.text(Textos.vencenPronto), findsOneWidget);
      expect(find.text(Textos.sinAbrirMoca), findsOneWidget);
      expect(find.textContaining('Pollería Rosa'), findsOneWidget);
      // Lo de Mercado Pago que quedó por revisar (entrega 32).
      expect(find.text(Textos.pagosPorRevisar), findsOneWidget);
      expect(
        find.text(
          'Bodega Don Lucho · 987 654 321 · S/\u00A014.90 · op 5005 · '
          '${Textos.motivoPorRevisar('monto')}',
        ),
        findsOneWidget,
      );
      expect(find.text('Bodega Don Lucho'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '999888777');
      await tester.pump();
      await tocar(tester, find.text(Textos.buscar));
      // Un número sin cuenta (entrega 47).
      expect(find.text(Textos.numeroSinCuenta47), findsOneWidget);

      // Tocar el negocio de la lista lo abre.
      await tocar(tester, find.text('Bodega Don Lucho').last);
      expect(find.text(Textos.registrarPago), findsOneWidget);
      expect(
        find.text(Textos.respondio(Textos.respuestaSi, 'S/\u00A014.90')),
        findsOneWidget,
      );
      // El uso de la semana (entrega 28).
      expect(find.text(Textos.usoDias(5, 4)), findsOneWidget);
      expect(find.text(Textos.usoVentas(6, 8)), findsOneWidget);
      expect(find.text(Textos.usoAvisos(3, 4)), findsOneWidget);

      await tocar(tester, find.text(Textos.registrarPago));
      // Con precio de fundador, viene elegido el plan de fundador.
      await tester.enterText(
        find.widgetWithText(TextField, Textos.notaDelPago),
        'op 123',
      );
      await tester.pump();
      // El de la hoja, encima del de la ficha.
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.registrarPago).last,
      );
      expect(
        find.text(
          Textos.confirmarPago(
            Textos.nombrePlan(PlanCobro.fundador),
            'Bodega Don Lucho',
          ),
        ),
        findsOneWidget,
      );
      await tocar(
        tester,
        find.widgetWithText(TextButton, Textos.registrarPago),
      );
      expect(_servidor.pagos.single, {
        'empresa': 'empresa-lucho',
        'plan': 'fundador',
        'nota': 'op 123',
      });
      expect(
        find.text(Textos.pagoRegistrado('14 de noviembre')),
        findsOneWidget,
      );
      expect(find.text(Textos.fundadoresUsados(1, 50)), findsOneWidget);
    });
  });

  testWidgets('Entrega 26.1: anular el último pago, después de confirmar', (
    tester,
  ) async {
    final base = await abrirApp(tester, listo: true);
    await tester.runAsync(() async {
      await _llavero.guardar('llave-de-prueba');
      await AccesoLocal(
        base,
        () => _ahora,
      ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321');
    });
    await esperar(tester);
    await tester.runAsync(
      () => AccesoLocal(base, () => _ahora).guardarAjuste(
        AccesoLocal.claveCobro,
        jsonEncode({'estado': 'sin_cobro', 'admin': true}),
      ),
    );
    await esperar(tester);
    _servidor.pagos.add({'plan': 'fundador'});
    await abrirAjusteOculto(tester);
    await tocar(tester, find.text(Textos.cobros));
    await tester.enterText(find.byType(TextField), '987654321');
    await tester.pump();
    await tocar(tester, find.text(Textos.buscar));

    await tocar(tester, find.text(Textos.anularPago));
    expect(find.text(Textos.anularPagoPregunta), findsOneWidget);
    await tocar(
      tester,
      find.widgetWithText(TextButton, Textos.anularPago).last,
    );
    expect(_servidor.anulados, ['pago-1']);
    expect(find.text(Textos.pagoAnulado), findsOneWidget);
    // Queda en la lista, anulado, y ya no se puede volver a anular.
    expect(find.textContaining('op 123 · ${Textos.anulado}'), findsOneWidget);
    expect(find.text(Textos.anularPago), findsNothing);
  });

  group('Entrega 25: el cobro en la app', () {
    /// El estado que mandaría el servidor, con la cuenta guardada.
    Future<BaseLocal> conCobro(
      WidgetTester tester,
      Map<String, Object?> cobro,
    ) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        await _llavero.guardar('llave-de-prueba');
        await AccesoLocal(
          base,
          () => _ahora,
        ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321');
      });
      await esperar(tester);
      await tester.runAsync(
        () => AccesoLocal(base, () => _ahora).guardarAjuste(
          AccesoLocal.claveCobro,
          jsonEncode({
            'precio': 1490,
            'pago': {'yape': '911111111', 'nombre': 'Moca'},
            ...cobro,
          }),
        ),
      );
      await esperar(tester);
      return base;
    }

    String dia(int dias) {
      final d = _ahora.add(Duration(days: dias));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    testWidgets('En prueba: la pestaña Moca dice cuántos días quedan y cómo '
        'pagar', (tester) async {
      await conCobro(tester, {'estado': 'prueba', 'hasta': dia(9), 'dias': 9});
      // Sin aviso en el Inicio: todavía no está por vencer.
      expect(find.text(Textos.comoPagar), findsNothing);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      // Los días en grande y hasta cuándo (mejora 01).
      expect(
        find.text(Textos.cuantosDias(9), findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining(Textos.cuantosDias(9), findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text(
          Textos.hastaEl(formatearDiaYMes(_ahora.add(const Duration(days: 9)))),
        ),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.activarMiPlan));
      expect(
        find.text(Textos.yapeaA('S/\u00A014.90', '911 111 111', 'Moca')),
        findsOneWidget,
      );
      expect(find.text(Textos.precioDeFundador), findsOneWidget);
      // Sin Mercado Pago en el servidor, solo el Yape (entrega 32).
      expect(find.text(Textos.pagarConMercadoPago), findsNothing);
      await tocar(tester, find.text(Textos.mandarLaCaptura));
      expect(_abiertos.single, startsWith('https://wa.me/51911111111?text='));
      expect(_abiertos.single, isNot(contains('+')));
      expect(
        Uri.parse(_abiertos.single).queryParameters['text'],
        contains('Bodega Don Lucho'),
      );
    });

    // La espera de Mercado Pago gira sin parar: aquí no hay pumpAndSettle.
    Future<void> avanzar(WidgetTester tester, Duration cuanto) async {
      await tester.pump(cuanto);
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }
    }

    Future<void> tocarSinEsperar(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.tap(f);
      await avanzar(tester, Duration.zero);
    }

    testWidgets('Entrega 43: elige Básico o Full, con sus personas extra', (
      tester,
    ) async {
      await conCobro(tester, {
        'estado': 'prueba',
        'hasta': dia(3),
        'dias': 3,
        'precio': 1990,
        'mercadopago': true,
        'personas': 2,
        'opciones': {
          'full': {'plan': 'normal', 'precio': 1990, 'extras': 0},
          'basico': {'plan': 'basico', 'precio': 1780, 'extras': 1},
        },
      });
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      await tocar(tester, find.text(Textos.activarMiPlan).first);
      expect(find.text(Textos.eligeTuPlan), findsOneWidget);
      // Viene el Full: tiene 2 personas, el Full incluye 3.
      expect(
        find.text(
          Textos.cuentaDelPlan(
            Textos.planFull,
            formatearSolesComprobante(1990),
            0,
            formatearSolesComprobante(0),
            formatearSolesComprobante(1990),
          ),
        ),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.planBasico));
      expect(
        find.text(
          Textos.cuentaDelPlan(
            Textos.planBasico,
            formatearSolesComprobante(1490),
            1,
            formatearSolesComprobante(290),
            formatearSolesComprobante(1780),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          Textos.avisoBasicoConExtras(1, formatearSolesComprobante(290)),
        ),
        findsOneWidget,
      );
      // S/ 17.80 sigue siendo menos que el Full.
      expect(
        find.text(Textos.conFullPagasMenos(formatearSolesComprobante(1990))),
        findsNothing,
      );
      await tester.ensureVisible(find.text(Textos.pagarConMercadoPago));
      await tester.tap(find.text(Textos.pagarConMercadoPago));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(_servidor.ultimaOrden, {'plan': 'basico'});
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text(Textos.seguirSinEsperar));
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('Entrega 43: si el Básico sale más caro, sugiere el Full', (
      tester,
    ) async {
      await conCobro(tester, {
        'estado': 'vencido',
        'hasta': dia(-2),
        'precio': 2280,
        'personas': 4,
        'opciones': {
          'full': {'plan': 'normal', 'precio': 2280, 'extras': 1},
          'basico': {'plan': 'basico', 'precio': 2360, 'extras': 3},
        },
      });
      await tocar(tester, find.text(Textos.comoPagar).first);
      await tocar(tester, find.text(Textos.planBasico));
      final sugerencia = find.text(
        Textos.conFullPagasMenos(formatearSolesComprobante(2280)),
      );
      expect(sugerencia, findsOneWidget);
      await tocar(tester, find.widgetWithText(TextButton, Textos.planFull));
      expect(sugerencia, findsNothing);
      expect(
        find.text(
          Textos.cuentaDelPlan(
            Textos.planFull,
            formatearSolesComprobante(1990),
            1,
            formatearSolesComprobante(290),
            formatearSolesComprobante(2280),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Entrega 43: el Básico no arma lo del crédito', (tester) async {
      await conCobro(tester, {
        'estado': 'pagado',
        'hasta': dia(20),
        'dias': 20,
        'plan': 'basico',
        'nivel': 'basico',
        'incluidas': 1,
        'credito': false,
        'opciones': {
          'full': {'plan': 'normal', 'precio': 1990, 'extras': 0},
          'basico': {'plan': 'basico', 'precio': 1490, 'extras': 0},
        },
      });
      await tocar(tester, find.text(Textos.pestanaInformes));
      await tocar(tester, find.text(Textos.compartir));
      await tocar(tester, find.text(Textos.compartirPdf));
      await tocar(tester, find.text(Textos.pdfParaCredito));
      expect(find.text(Textos.creditoEsDelFull), findsOneWidget);
      await tocar(tester, find.text(Textos.comoPagar));
      // «Cómo pagar» se abre con el Básico que tiene.
      expect(find.text(Textos.eligeTuPlan), findsOneWidget);
      expect(
        find.text(
          Textos.cuentaDelPlan(
            Textos.planBasico,
            formatearSolesComprobante(1490),
            0,
            formatearSolesComprobante(0),
            formatearSolesComprobante(1490),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Entrega 32: paga con Mercado Pago y Moca queda pagada', (
      tester,
    ) async {
      await conCobro(tester, {
        'estado': 'prueba',
        'hasta': dia(9),
        'dias': 9,
        'mercadopago': true,
      });
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      await tocar(tester, find.text(Textos.activarMiPlan));
      // El fundador no ve el Básico: solo la cuenta del Full (entrega 43).
      expect(find.text(Textos.eligeTuPlan), findsNothing);
      expect(
        find.text(
          Textos.cuentaDelPlan(
            Textos.planFull,
            'S/\u00A014.90',
            0,
            'S/\u00A00.00',
            'S/\u00A014.90',
          ),
        ),
        findsOneWidget,
      );
      // El Yape manual queda debajo, con su botón ya no principal.
      expect(find.text(Textos.oYapeaYMandaLaCaptura), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, Textos.mandarLaCaptura),
        findsOneWidget,
      );

      await tocarSinEsperar(tester, find.text(Textos.pagarConMercadoPago));
      expect(_servidor.ordenesPedidas, 1);
      expect(_abiertos.single, 'https://mp.falso/pagar/orden-1');
      expect(find.text(Textos.esperandoElPago), findsOneWidget);

      await avanzar(tester, const Duration(seconds: 3));
      expect(_servidor.consultasDeOrden, 1);
      expect(find.text(Textos.esperandoElPago), findsOneWidget);

      final hasta = _ahora.add(const Duration(days: 39));
      _servidor.orden = {
        'estado': 'pagada',
        'cobro': {
          'estado': 'pagado',
          'hasta': dia(39),
          'dias': 39,
          'plan': 'fundador',
          'precio': 1490,
          'mercadopago': true,
        },
      };
      await avanzar(tester, const Duration(seconds: 3));
      await esperar(tester);
      expect(find.text(Textos.esperandoElPago), findsNothing);
      expect(find.text(Textos.pagaTuMes), findsNothing);
      expect(
        find.text(Textos.mocaPagadaHasta(formatearDiaYMes(hasta))),
        findsOneWidget,
      );
      expect(
        find.text(Textos.pagadoHasta(formatearDiaYMes(hasta))),
        findsOneWidget,
      );
    });

    testWidgets('Entrega 32: «Seguir sin esperar» y sin Mercado Pago', (
      tester,
    ) async {
      await conCobro(tester, {
        'estado': 'prueba',
        'hasta': dia(9),
        'dias': 9,
        'mercadopago': true,
      });
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      await tocar(tester, find.text(Textos.activarMiPlan));
      await tocarSinEsperar(tester, find.text(Textos.pagarConMercadoPago));
      await tocarSinEsperar(tester, find.text(Textos.seguirSinEsperar));
      await avanzar(tester, const Duration(seconds: 10));
      expect(find.text(Textos.esperandoElPago), findsNothing);
      expect(_servidor.consultasDeOrden, 0);
      // Sigue en «Cómo pagar», por si quiere yapear.
      expect(find.text(Textos.pagaTuMes), findsOneWidget);

      // Si el servidor no tiene Mercado Pago, lo dice y no abre nada.
      _abiertos.clear();
      _servidor.errorMercadoPago = 'sin_mercadopago';
      await tocar(tester, find.text(Textos.pagarConMercadoPago));
      expect(_abiertos, isEmpty);
      expect(find.text(Textos.pagoNoDisponible), findsOneWidget);
    });

    testWidgets('Entrega 32.2: ya pagada, «Pagar otro mes» dice qué cubre', (
      tester,
    ) async {
      await conCobro(tester, {
        'estado': 'pagado',
        'hasta': dia(30),
        'dias': 30,
        'plan': 'fundador',
        'mercadopago': true,
      });
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(Textos.comoPagar), findsNothing);
      await tocar(tester, find.text(Textos.pagarOtroMes));
      final hasta = _ahora.add(const Duration(days: 30));
      final desde = DateTime(hasta.year, hasta.month, hasta.day + 1);
      final nuevo = DateTime(desde.year, desde.month + 1, desde.day - 1);
      expect(
        find.text(
          Textos.pagoSumaUnMes(
            formatearDiaYMes(hasta),
            formatearDiaYMes(desde),
            formatearDiaYMes(nuevo),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(Textos.pagarConMercadoPago), findsOneWidget);
    });

    testWidgets('Entrega 32.2: con 60 días pagados ya no se adelanta', (
      tester,
    ) async {
      await conCobro(tester, {
        'estado': 'pagado',
        'hasta': dia(60),
        'dias': 60,
        'plan': 'fundador',
      });
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(Textos.pagarOtroMes), findsNothing);
      expect(find.text(Textos.comoPagar), findsNothing);
    });

    testWidgets('Entrega 32.2: el ayudante no paga ni adelanta', (
      tester,
    ) async {
      final base = await conCobro(tester, {
        'estado': 'pagado',
        'hasta': dia(30),
        'dias': 30,
        'plan': 'fundador',
      });
      await tester.runAsync(
        () => base
            .update(base.membresias)
            .write(const MembresiasCompanion(rol: Value(Rol.ayudante))),
      );
      await esperar(tester);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(Textos.pagarOtroMes), findsNothing);
    });

    testWidgets('Entrega 33: «Mis pagos de Moca», también sin señal', (
      tester,
    ) async {
      await conCobro(tester, {
        'estado': 'pagado',
        'hasta': dia(30),
        'dias': 30,
        'plan': 'fundador',
      });
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      await tocar(tester, find.text(Textos.verMisPagos));
      await esperar(tester);
      expect(
        find.text(
          'Moca está pagada hasta el '
          '${formatearDiaYMes(_ahora.add(const Duration(days: 30)))} · '
          'Plan de fundador',
        ),
        findsOneWidget,
      );
      expect(find.text(Textos.pagoEnRevision), findsOneWidget);
      expect(find.text('Del 26 de diciembre al 25 de enero'), findsOneWidget);
      expect(find.text(Textos.porYape), findsOneWidget);
      expect(find.text(Textos.porMercadoPago('5001')), findsOneWidget);
      expect(find.text(Textos.pagoDevueltoNoCuenta), findsOneWidget);
      expect(
        find.text(Textos.planDelPago(PlanCobro.fundador)),
        findsNWidgets(2),
      );
      expect(find.textContaining('Actualizado el'), findsNothing);

      // Sin señal: la última lista que bajó.
      await tocar(tester, find.byType(BotonVolver));
      _conSenal = false;
      await tocar(tester, find.text(Textos.verMisPagos));
      await esperar(tester);
      expect(find.text(Textos.porMercadoPago('5001')), findsOneWidget);
      expect(find.textContaining('Actualizado el'), findsOneWidget);
    });

    testWidgets('Entrega 33: en «Ajustes», solo para dueños', (tester) async {
      final base = await conCobro(tester, {
        'estado': 'prueba',
        'hasta': dia(9),
        'dias': 9,
      });
      await abrirAjustes(tester);
      expect(find.text(Textos.misPagos), findsOneWidget);
      // En la prueba, sin pagos: no sale «Ver mis pagos» en la tarjeta.
      await tocar(tester, find.byType(BotonVolver));
      expect(find.text(Textos.verMisPagos), findsNothing);
      await tester.runAsync(
        () => base
            .update(base.membresias)
            .write(const MembresiasCompanion(rol: Value(Rol.encargado))),
      );
      await esperar(tester);
      await abrirAjustes(tester);
      expect(find.text(Textos.misPagos), findsNothing);
    });

    testWidgets('Por vencer: el aviso sale en el Inicio', (tester) async {
      await conCobro(tester, {
        'estado': 'prueba',
        'hasta': dia(2),
        'dias': 2,
        'porVencer': true,
      });
      expect(find.text(Textos.avisoPorVencer(true, 2)), findsOneWidget);
      expect(find.text(Textos.comoPagar), findsOneWidget);
      expect(find.text(Textos.tienesHoy), findsOneWidget);
    });

    testWidgets('Al vencer: solo anotar, sin saldos ni Informes', (
      tester,
    ) async {
      await conCobro(tester, {'estado': 'vencido', 'hasta': dia(-1)});
      expect(find.text(Textos.pruebaTermino), findsOneWidget);
      expect(find.text(Textos.soloAnotarDetalle), findsOneWidget);
      expect(find.text(Textos.tienesHoy), findsNothing);
      expect(find.text(Textos.pestanaInformes), findsNothing);
      expect(find.text(Textos.bajarMisOperaciones), findsOneWidget);
      // Se sigue anotando.
      await tocar(tester, find.text(Textos.anotarVentaDeHoy));
      expect(find.text(Textos.pruebaTermino), findsNothing);
    });

    testWidgets('Sin señal, vence igual al pasar el último día', (
      tester,
    ) async {
      await conCobro(tester, {'estado': 'prueba', 'hasta': dia(-2), 'dias': 0});
      expect(find.text(Textos.pruebaTermino), findsOneWidget);
    });

    testWidgets('La pregunta del día 10 se contesta una vez', (tester) async {
      await conCobro(tester, {'estado': 'prueba', 'hasta': dia(4), 'dias': 4});
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      final pregunta = Textos.preguntaPrecio('S/\u00A014.90');
      expect(find.text(pregunta), findsOneWidget);
      await tocar(tester, find.text(Textos.respuestaNoSe));
      await tester.enterText(
        find.widgetWithText(TextField, Textos.porQueOpcional),
        'Depende de las ventas',
      );
      await tester.pump();
      await tocar(tester, find.text(Textos.enviarRespuesta));
      expect(_servidor.respuestasDePrecio.single, {
        'respuesta': 'no_se',
        'motivo': 'Depende de las ventas',
      });
      expect(find.text(Textos.graciasPorResponder), findsOneWidget);
      expect(find.text(pregunta), findsNothing);
    });

    testWidgets('Sin cobro (sin cuenta o antes de empezar), nada cambia', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      expect(find.text(Textos.comoPagar), findsNothing);
      expect(find.textContaining('Prueba gratis'), findsNothing);
    });
  });

  group('Entrega 22.2: «Salir de este negocio» en «Seguridad»', () {
    Future<BaseLocal> conCuenta(
      WidgetTester tester, {
      required bool titular,
    }) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        await _llavero.guardar('llave-de-prueba');
        await AccesoLocal(
          base,
          () => _ahora,
        ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321');
      });
      await esperar(tester);
      await tester.runAsync(() async {
        final acceso = AccesoLocal(base, () => _ahora);
        final yo = await acceso.usuario();
        await acceso.guardarAjuste(
          AccesoLocal.claveEquipo,
          jsonEncode([
            if (!titular)
              {'usuario_id': 'otro', 'rol': 'dueno', 'titular': true},
            {'usuario_id': yo.id, 'rol': 'dueno', 'titular': titular},
          ]),
        );
      });
      await esperar(tester);
      await abrirAjustes(tester);
      await tester.scrollUntilVisible(
        find.text(Textos.pedirHuella),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await esperar(tester);
      return base;
    }

    testWidgets('El titular borra; no sale', (tester) async {
      await conCuenta(tester, titular: true);
      expect(find.text(Textos.seguridad.toUpperCase()), findsOneWidget);
      expect(find.text(Textos.borrarMiNegocio), findsOneWidget);
      expect(find.text(Textos.salirDelNegocio), findsNothing);
    });

    testWidgets('Quien no es titular sale, después de confirmar', (
      tester,
    ) async {
      await conCuenta(tester, titular: false);
      expect(find.text(Textos.borrarMiNegocio), findsNothing);
      await tocar(tester, find.text(Textos.salirDelNegocio));
      expect(find.text(Textos.salirDelNegocioPregunta), findsOneWidget);
      await tocar(tester, find.text(Textos.cancelar));
      expect(_servidor.salidas, 0);

      await tocar(tester, find.text(Textos.salirDelNegocio));
      await tocar(tester, find.widgetWithText(TextButton, Textos.salir));
      expect(_servidor.salidas, 1);
      expect(find.text(Textos.salisteDelNegocio), findsOneWidget);
      // Entrega 37: su copia del negocio se borra y queda solo qué pasó.
      expect(
        find.text(
          Textos.sinAccesoTitulo(
            const SinAcceso(
              motivo: MotivoSinAcceso.salio,
              negocio: 'Bodega Don Lucho',
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(Textos.tienesHoy), findsNothing);
    });
  });

  group('Entrega 16.3: pedir huella al abrir Moca', () {
    Future<void> salirYVolver(WidgetTester tester, Duration fuera) async {
      for (final estado in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(estado);
      }
      _ahora = _ahora.add(fuera);
      for (final estado in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(estado);
      }
      await esperar(tester);
    }

    Future<void> alInterruptor(WidgetTester tester) async {
      await abrirAjustes(tester);
      await tester.scrollUntilVisible(
        find.text(Textos.pedirHuella),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }

    testWidgets('Apagada no pide nada', (tester) async {
      await abrirApp(tester, listo: true);
      expect(find.text(Textos.mocaProtegida), findsNothing);
      await salirYVolver(tester, const Duration(minutes: 10));
      expect(find.text(Textos.mocaProtegida), findsNothing);
      expect(_huellasPedidas, 0);
    });

    testWidgets('Se enciende en la pestaña Moca, pidiéndola una vez', (
      tester,
    ) async {
      await abrirApp(tester, listo: true);
      await alInterruptor(tester);
      await tocar(tester, find.text(Textos.pedirHuella));
      expect(_huellasPedidas, 1);
      expect(find.text(Textos.huellaActivada), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      // Ya encendida, al volver a los 6 minutos la pide.
      _pasaLaHuella = false;
      await salirYVolver(tester, const Duration(minutes: 6));
      expect(_huellasPedidas, 2);
      expect(find.text(Textos.mocaProtegida), findsOneWidget);
    });

    testWidgets('Sin bloqueo en el teléfono no se enciende', (tester) async {
      await abrirApp(tester, listo: true);
      _hayBloqueo = false;
      await alInterruptor(tester);
      await tocar(tester, find.text(Textos.pedirHuella));
      expect(find.text(Textos.sinBloqueoEnElTelefono), findsOneWidget);
      expect(_huellasPedidas, 0);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('Encendida, la pide al abrir; si falla, no se ve nada', (
      tester,
    ) async {
      await abrirApp(tester, listo: true, conHuella: true, pasaLaHuella: false);
      expect(_huellasPedidas, 1);
      expect(find.text(Textos.mocaProtegida), findsOneWidget);
      // La pantalla de abajo no se puede tocar.
      expect(find.text(Textos.tienesHoy).hitTestable(), findsNothing);

      _pasaLaHuella = true;
      await tocar(tester, find.text(Textos.usarHuella));
      expect(find.text(Textos.mocaProtegida), findsNothing);
      expect(find.text(Textos.tienesHoy).hitTestable(), findsOneWidget);
    });

    testWidgets('Al volver en menos de 5 minutos no la pide; después, sí', (
      tester,
    ) async {
      await abrirApp(tester, listo: true, conHuella: true);
      expect(find.text(Textos.mocaProtegida), findsNothing);
      expect(_huellasPedidas, 1);

      await salirYVolver(tester, const Duration(minutes: 4));
      expect(find.text(Textos.mocaProtegida), findsNothing);
      expect(_huellasPedidas, 1);

      _pasaLaHuella = false;
      await salirYVolver(tester, const Duration(minutes: 6));
      expect(_huellasPedidas, 2);
      expect(find.text(Textos.mocaProtegida), findsOneWidget);
    });
  });

  group('Entrega 16.1: «Borrar mi negocio» a la vista del titular', () {
    Future<BaseLocal> conCuentaGuardada(WidgetTester tester) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        await _llavero.guardar('llave-de-prueba');
        await AccesoLocal(
          base,
          () => _ahora,
        ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321');
      });
      await esperar(tester);
      return base;
    }

    /// El enlace está al final de la pestaña Moca.
    Future<void> abrirBorrar(WidgetTester tester) async {
      await abrirAjustes(tester);
      await tester.scrollUntilVisible(
        find.text(Textos.borrarMiNegocio),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.borrarMiNegocio));
    }

    testWidgets('Sin cuenta guardada no aparece', (tester) async {
      await abrirApp(tester, listo: true);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      // Hasta el final de la pestaña: la lista se arma al verse.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await esperar(tester);
      expect(find.text(Textos.borrarMiNegocio), findsNothing);
    });

    testWidgets('Un dueño que no es el titular no lo ve', (tester) async {
      final base = await conCuentaGuardada(tester);
      await tester.runAsync(() async {
        final acceso = AccesoLocal(base, () => _ahora);
        final yo = await acceso.usuario();
        await acceso.guardarAjuste(
          AccesoLocal.claveEquipo,
          jsonEncode([
            {'usuario_id': 'otro', 'rol': 'dueno', 'titular': true},
            {'usuario_id': yo.id, 'rol': 'dueno', 'titular': false},
          ]),
        );
      });
      await esperar(tester);
      await abrirAjustes(tester);
      expect(find.text(Textos.misNegocios), findsOneWidget);
      // Hasta el final de la pestaña: la lista se arma al verse.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await esperar(tester);
      expect(find.text(Textos.borrarMiNegocio), findsNothing);
    });

    testWidgets('El titular lo ve, escribe BORRAR y queda como recién '
        'instalada', (tester) async {
      final base = await conCuentaGuardada(tester);
      await abrirBorrar(tester);
      expect(find.text(Textos.seGuardaElNumero), findsOneWidget);
      expect(find.text(Textos.antesDeBorrar), findsOneWidget);

      final boton = find.widgetWithText(FilledButton, Textos.borrarParaSiempre);
      expect(tester.widget<FilledButton>(boton).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'borrar');
      await tester.pump();
      await tocar(tester, boton);

      expect(_servidor.borrados, ['BORRAR']);
      expect(find.text(Textos.seBorroTodoEnServidor), findsOneWidget);
      expect(find.text(Textos.anotarPrimeraVenta), findsOneWidget);
      expect(
        (await tester.runAsync(() => base.select(base.movimientos).get()))!,
        isEmpty,
      );
    });

    testWidgets('Sin señal lo dice y no borra nada', (tester) async {
      final base = await conCuentaGuardada(tester);
      await abrirBorrar(tester);
      _conSenal = false;
      await tester.enterText(find.byType(TextField), 'BORRAR');
      await tester.pump();
      await tocar(
        tester,
        find.widgetWithText(FilledButton, Textos.borrarParaSiempre),
      );
      expect(find.text(Textos.borrarSinSenal), findsOneWidget);
      expect(_servidor.borrados, isEmpty);
      expect(
        (await tester.runAsync(() => base.select(base.movimientos).get()))!,
        isNotEmpty,
      );
    });
  });

  testWidgets('La primera semana muestra cuánto hay en cada cuenta '
      '(entrega 14.9)', (tester) async {
    await abrirApp(tester, listo: true);
    expect(find.text(Textos.tusPrimerosPasos), findsOneWidget);
    // S/ 1,000 de saldo más la venta de S/ 350, todo en efectivo.
    expect(find.text(Textos.tienesHoy), findsOneWidget);
    expect(find.text(Textos.efectivo), findsOneWidget);
    expect(find.text(Textos.yape), findsOneWidget);
    expect(find.text(Textos.banco), findsOneWidget);
    expect(find.text(formatearSoles(135000)), findsNWidgets(2));
    expect(find.text(formatearSoles(0)), findsNWidgets(2));
  });

  group('Entregas 29 y 29.1: «Ajustes» y «Datos del negocio»', () {
    Future<BaseLocal> conCuenta(WidgetTester tester, {Rol? rol}) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        await _llavero.guardar('llave-de-prueba');
        await AccesoLocal(
          base,
          () => _ahora,
        ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321');
      });
      await esperar(tester);
      if (rol != null) {
        await tester.runAsync(
          () => base
              .update(base.membresias)
              .write(MembresiasCompanion(rol: Value(rol))),
        );
        await esperar(tester);
      }
      return base;
    }

    testWidgets('La pestaña Moca deja lo del día y lleva a «Ajustes»', (
      tester,
    ) async {
      await conCuenta(tester);
      await tocar(tester, find.text(Textos.pestanaMoca).last);
      for (final texto in [
        Textos.misCuentas,
        Textos.miEquipo,
        Textos.misNegocios,
        Textos.pedirHuella,
        Textos.borrarMiNegocio,
      ]) {
        expect(find.text(texto), findsNothing, reason: texto);
      }
      await abrirAjustes(tester);
      expect(find.text(Textos.tuNegocio.toUpperCase()), findsOneWidget);
      expect(find.text(Textos.datosDelNegocio), findsOneWidget);
      expect(find.text(Textos.misCuentas), findsOneWidget);
      expect(find.text(Textos.tuEquipoAjustes.toUpperCase()), findsOneWidget);
      expect(find.text(Textos.miEquipo), findsOneWidget);
      expect(find.text(Textos.misNegocios), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(Textos.borrarMiNegocio),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(Textos.pedirHuella), findsOneWidget);
    });

    testWidgets('El ayudante no ve «Tu negocio»; sí la huella y salir', (
      tester,
    ) async {
      await conCuenta(tester, rol: Rol.ayudante);
      await abrirAjustes(tester);
      expect(find.text(Textos.tuNegocio.toUpperCase()), findsNothing);
      expect(find.text(Textos.datosDelNegocio), findsNothing);
      expect(find.text(Textos.misCuentas), findsNothing);
      expect(find.text(Textos.miEquipo), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(Textos.salirDelNegocio),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(Textos.pedirHuella), findsOneWidget);
      expect(find.text(Textos.borrarMiNegocio), findsNothing);
    });

    testWidgets('El dueño cambia el nombre y la hora, y se sube', (
      tester,
    ) async {
      final base = await conCuenta(tester);
      await tester.pump(const Duration(seconds: 6));
      await esperar(tester);
      final antes = _servidor.subidas.length;
      await abrirAjustes(tester);
      await tocar(tester, find.text(Textos.datosDelNegocio));
      expect(find.text('Bodega Don Lucho'), findsOneWidget);
      expect(find.text(formatearHora(21 * 60)), findsOneWidget);
      final guardar = find.widgetWithText(FilledButton, Textos.guardar);
      expect(tester.widget<FilledButton>(guardar).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Bodega Lucho');
      await tester.pump();
      // El reloj abre con la hora de cierre; la hora nueva y su aviso se
      // prueban en repositorio_negocio_test.
      await tocar(tester, find.text(Textos.aQueHoraCierras));
      expect(find.byType(Dialog), findsOneWidget);
      await tocar(
        tester,
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(TextButton),
            )
            .first,
      );
      expect(find.byType(Dialog), findsNothing);
      await tocar(tester, guardar);
      expect(find.text(Textos.datosGuardados), findsOneWidget);
      expect(find.text(Textos.tuNegocio.toUpperCase()), findsOneWidget);

      final empresa = await tester.runAsync(
        () => base.select(base.empresas).getSingle(),
      );
      expect(empresa!.nombre, 'Bodega Lucho');
      expect(empresa.horaCierreMinutos, 21 * 60);
      await tester.pump(const Duration(seconds: 6));
      await esperar(tester);
      expect(_servidor.subidas.length, greaterThan(antes));
      final subida = _servidor.subidas.last['empresa']! as Map;
      expect(subida['nombre'], 'Bodega Lucho');
      expect(subida['hora_cierre_minutos'], 21 * 60);
    });
  });

  group('Entrega 31: categorías propias', () {
    Future<BaseLocal> conCuenta(WidgetTester tester, {Rol? rol}) async {
      final base = await abrirApp(tester, listo: true);
      await tester.runAsync(() async {
        await _llavero.guardar('llave-de-prueba');
        await AccesoLocal(
          base,
          () => _ahora,
        ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321');
      });
      await esperar(tester);
      if (rol != null) {
        await tester.runAsync(
          () => base
              .update(base.membresias)
              .write(MembresiasCompanion(rol: Value(rol))),
        );
        await esperar(tester);
      }
      return base;
    }

    // El aviso de abajo tapa los botones: se espera a que se vaya.
    Future<void> sinAviso(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 5));
      await esperar(tester);
    }

    Future<void> nueva(WidgetTester tester, String nombre) async {
      await tester.enterText(find.byType(TextField), nombre);
      await tester.pump();
    }

    testWidgets('El dueño agrega, cambia y deja de usar una; se sube', (
      tester,
    ) async {
      await conCuenta(tester);
      await tester.pump(const Duration(seconds: 6));
      await esperar(tester);
      await abrirAjustes(tester);
      await tocar(tester, find.text(Textos.misCategorias));
      expect(find.text(Textos.categoriasDeMoca), findsOneWidget);
      expect(find.text('Venta del día'), findsOneWidget);
      expect(find.text(Textos.tuya), findsNothing);

      await tocar(tester, find.text(Textos.agregarCategoria));
      await nueva(tester, 'Hielo');
      final guardar = find.widgetWithText(FilledButton, Textos.guardar);
      // Falta elegir si entra o sale.
      expect(tester.widget<FilledButton>(guardar).onPressed, isNull);
      await tocar(tester, find.text(Textos.loQueSale));
      await tocar(tester, guardar);
      expect(find.text(Textos.categoriaAgregada), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Hielo'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(Textos.tuya), findsOneWidget);
      await sinAviso(tester);

      // Una repetida no entra.
      await tocar(tester, find.text(Textos.agregarCategoria));
      await nueva(tester, 'mercaderia');
      await tocar(tester, find.text(Textos.loQueSale));
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(find.text(Textos.categoriaRepetida), findsOneWidget);
      await tocar(tester, find.byType(BotonVolver));

      // Cambiar el nombre y dejar de usarla.
      await tester.scrollUntilVisible(
        find.text('Hielo'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text('Hielo'));
      await nueva(tester, 'Hielo y agua');
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      await sinAviso(tester);
      await tester.scrollUntilVisible(
        find.text('Hielo y agua'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text('Hielo y agua'));
      await tocar(tester, find.text(Textos.yaNoLaUso));
      expect(find.text(Textos.categoriaSinUso), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(Textos.yaNoLaUsas),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.pump(const Duration(seconds: 6));
      await esperar(tester);
      final subida = _servidor.subidas.last['categorias']! as List;
      final hielo = subida.cast<Map>().firstWhere(
        (c) => c['nombre'] == 'Hielo y agua',
      );
      expect(hielo['tipo_movimiento'], 'egreso');
      expect(hielo['activa'], false);
    });

    testWidgets('«+ Otra categoría» al anotar la deja elegida', (tester) async {
      final base = await abrirApp(tester, listo: true);
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      await tocar(tester, find.text(Textos.salio));
      await tester.enterText(find.byType(TextField).first, '8');
      await tester.pump();
      await tocar(tester, find.text(Textos.efectivo));
      await tester.scrollUntilVisible(
        find.text(Textos.otraCategoria),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.otraCategoria));
      // Ya sabe que es de lo que sale: no lo pregunta.
      expect(find.text(Textos.esDeLoQue), findsNothing);
      await nueva(tester, 'Hielo');
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));
      expect(find.text('Hielo'), findsOneWidget);
      await sinAviso(tester);
      await tocar(tester, find.widgetWithText(FilledButton, Textos.guardar));

      final guardado = await tester.runAsync(() async {
        final m = await (base.select(
          base.movimientos,
        )..where((m) => m.montoCentimos.equals(800))).getSingle();
        return (await (base.select(
          base.categorias,
        )..where((c) => c.id.equals(m.categoriaId!))).getSingle()).nombre;
      });
      expect(guardado, 'Hielo');
    });

    testWidgets('El ayudante no agrega categorías', (tester) async {
      await conCuenta(tester, rol: Rol.ayudante);
      await abrirAjustes(tester);
      expect(find.text(Textos.misCategorias), findsNothing);
      await tocar(tester, find.byType(BotonVolver));
      await tocar(tester, find.bySemanticsLabel(Textos.registrar));
      await tocar(tester, find.text(Textos.escribirlo));
      await tocar(tester, find.text(Textos.salio));
      expect(find.text(Textos.otraCategoria), findsNothing);
    });
  });

  group('Entrega 37: sin acceso al negocio', () {
    Future<BaseLocal> otraDuena(WidgetTester tester) async {
      final base = await abrirApp(tester, listo: true);
      // Una escritura por bloque: varias juntas se traban en las pruebas.
      await tester.runAsync(() => _llavero.guardar('llave-de-prueba'));
      await tester.runAsync(
        () => AccesoLocal(
          base,
          () => _ahora,
        ).guardarAjuste(AccesoLocal.claveCuentaVerificada, '987654321'),
      );
      await esperar(tester);
      final yo = await tester.runAsync(
        () => AccesoLocal(base, () => _ahora).usuario(),
      );
      await tester.runAsync(
        () => AccesoLocal(base, () => _ahora).guardarAjuste(
          AccesoLocal.claveEquipo,
          jsonEncode([
            {'usuario_id': 'lucho', 'rol': 'dueno', 'titular': true},
            {'usuario_id': yo!.id, 'rol': 'dueno', 'titular': false},
          ]),
        ),
      );
      await esperar(tester);
      return base;
    }

    // Lo que la app hace cada 30 segundos: preguntar por lo nuevo. Corre en
    // el reloj de la prueba, con tiempo real para la base entre cuadros.
    Future<void> traer(WidgetTester tester) async {
      var listo = false;
      unawaited(
        ProviderScope.containerOf(tester.element(find.byType(MocaApp)))
            .read(servicioCuentaProvider)
            .traerCambios()
            .whenComplete(() => listo = true),
      );
      for (var i = 0; i < 100 && !listo; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await esperar(tester);
    }

    testWidgets('El titular borró el negocio: la otra dueña queda sin datos y '
        'con salida', (tester) async {
      final base = await otraDuena(tester);
      expect(find.text(Textos.tienesHoy), findsOneWidget);
      _servidor.sinAccesoAlNegocio = 'negocio_borrado';
      await traer(tester);
      expect(
        find.text(
          Textos.sinAccesoTitulo(
            const SinAcceso(
              motivo: MotivoSinAcceso.negocioBorrado,
              negocio: 'Bodega Don Lucho',
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(Textos.sinAccesoDetalle(MotivoSinAcceso.negocioBorrado)),
        findsOneWidget,
      );
      // Nada del negocio detrás, ni en el teléfono.
      expect(find.text(Textos.tienesHoy), findsNothing);
      expect(find.text(Textos.pestanaHistorial), findsNothing);
      final quedan = await tester.runAsync(
        () async => (
          await base.select(base.movimientos).get(),
          await base.select(base.empresas).get(),
        ),
      );
      expect(quedan!.$1, isEmpty);
      expect(quedan.$2, isEmpty);

      // Empezar su propio negocio: a la Bienvenida.
      await tocar(tester, find.text(Textos.empezarMiNegocio));
      expect(find.text(Textos.anotarPrimeraVenta), findsOneWidget);
    });

    testWidgets('A quien quitaron ve sus negocios e invitaciones', (
      tester,
    ) async {
      await otraDuena(tester);
      _servidor.sinAccesoAlNegocio = 'quitado';
      await traer(tester);
      expect(
        find.text(Textos.sinAccesoDetalle(MotivoSinAcceso.quitado)),
        findsOneWidget,
      );
      await tocar(tester, find.text(Textos.verMisNegociosEInvitaciones));
      expect(find.text(Textos.misNegocios), findsWidgets);
    });

    testWidgets('«Salir de Moca en este teléfono» borra solo aquí', (
      tester,
    ) async {
      await otraDuena(tester);
      await abrirAjustes(tester);
      await tester.scrollUntilVisible(
        find.text(Textos.salirDeMocaAqui),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tocar(tester, find.text(Textos.salirDeMocaAqui));
      expect(find.text(Textos.salirDeMocaAquiPregunta), findsOneWidget);
      await tocar(tester, find.widgetWithText(TextButton, Textos.salir));
      expect(find.text(Textos.anotarPrimeraVenta), findsOneWidget);
      // El negocio no se tocó: no salió del equipo.
      expect(_servidor.salidas, 0);
    });
  });

  group('Entrega 39: buscar y filtrar en el Historial', () {
    Future<void> conGasto(WidgetTester tester) async {
      final base = await abrirApp(tester, listo: true);
      final movimientos = RepositorioMovimientosLocal(
        base,
        ahora: () => _ahora,
      );
      final mercaderia = await tester.runAsync(
        () async =>
            (await movimientos.categorias(TipoMovimiento.egreso))
                .firstWhere((c) => c.nombre == 'Mercadería')
                .id,
      );
      await tester.runAsync(
        () => movimientos.registrar(
          NuevoMovimiento(
            tipo: TipoMovimiento.egreso,
            montoCentimos: 8050,
            cuenta: TipoCuenta.efectivo,
            categoriaId: mercaderia,
            nota: 'Jhony Salar Vela',
          ),
        ),
      );
      await esperar(tester);
      await tocar(tester, find.text(Textos.pestanaHistorial));
    }

    testWidgets('Cada palabra tiene que estar, en cualquier orden', (
      tester,
    ) async {
      await conGasto(tester);
      expect(find.text('Venta del día'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'vela jhony');
      await tester.pump();
      expect(find.text('Jhony Salar Vela'), findsOneWidget);
      expect(find.text('Venta del día'), findsNothing);
      expect(
        find.text(
          Textos.resumenDeBusqueda(1, formatearSoles(0), formatearSoles(8050)),
        ),
        findsOneWidget,
      );
      // Una palabra que no está: nada.
      await tester.enterText(find.byType(TextField), 'jhony paredes');
      await tester.pump();
      expect(find.text(Textos.sinResultados), findsOneWidget);
      await tocar(tester, find.text(Textos.quitarFiltros));
      expect(find.text('Venta del día'), findsOneWidget);
      expect(find.text('Jhony Salar Vela'), findsOneWidget);
      // El monto.
      await tester.enterText(find.byType(TextField), '80.50');
      await tester.pump();
      expect(find.text('Jhony Salar Vela'), findsOneWidget);
      expect(find.text('Venta del día'), findsNothing);
    });

    testWidgets('El ayudante busca solo en lo de hoy', (tester) async {
      final base = await abrirApp(tester, listo: true);
      // Un gasto de ayer, con la nota que se va a buscar.
      final ayer = RepositorioMovimientosLocal(
        base,
        ahora: () => _ahora.subtract(const Duration(days: 1)),
      );
      final mercaderia = await tester.runAsync(
        () async =>
            (await ayer.categorias(TipoMovimiento.egreso))
                .firstWhere((c) => c.nombre == 'Mercadería')
                .id,
      );
      await tester.runAsync(
        () => ayer.registrar(
          NuevoMovimiento(
            tipo: TipoMovimiento.egreso,
            montoCentimos: 8050,
            cuenta: TipoCuenta.efectivo,
            categoriaId: mercaderia,
            nota: 'Jhony Salar Vela',
          ),
        ),
      );
      await tester.runAsync(
        () => base
            .update(base.membresias)
            .write(const MembresiasCompanion(rol: Value(Rol.ayudante))),
      );
      await esperar(tester);
      await tocar(tester, find.text(Textos.pestanaHistorial));
      await tester.enterText(find.byType(TextField), 'jhony');
      await tester.pump();
      expect(find.text('Jhony Salar Vela'), findsNothing);
      expect(find.text(Textos.sinResultados), findsOneWidget);
    });

    testWidgets(
      '«Filtrar» por categoría; sin «Quién lo anotó» si es uno solo',
      (tester) async {
        await conGasto(tester);
        // «Filtrar» es el botón del encabezado (mejora 01).
        await tocar(tester, find.byTooltip(Textos.filtrar));
        expect(find.text(Textos.quienAnoto), findsNothing);
        await tocar(tester, find.text('Mercadería').last);
        await tocar(tester, find.text(Textos.verResultados));
        expect(find.byTooltip(Textos.filtrarCon(1)), findsOneWidget);
        expect(find.text('Jhony Salar Vela'), findsOneWidget);
        expect(find.text('Venta del día'), findsNothing);
      },
    );
  });
}
