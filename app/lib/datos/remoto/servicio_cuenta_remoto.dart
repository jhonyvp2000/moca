import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../../dominio/cuenta_real.dart';
import '../../dominio/modelos.dart';
import '../local/base_local.dart';
import '../repositorios/acceso_local.dart';

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
  final http.Client _cliente;
  final Future<bool> Function() _hayConexion;
  final Uri _servidor;

  /// El servidor gratuito de Render se duerme y tarda en despertar.
  static const _espera = Duration(seconds: 75);

  /// Lo que subió la última vez, para no repetir subidas sin cambios.
  static const _claveHuellaSubida = 'subida_huella';
  static const _claveSinCuentaDesde = 'sin_cuenta_desde';

  /// A los cuántos días de «Ahora no» aparece la tarjeta de Moca.
  static const diasParaRecordar = 3;

  Future<http.Response> _enviar(String ruta, Object cuerpo, {String? llave}) =>
      _cliente
          .post(
            _servidor.resolve(ruta),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': ?(llave == null ? null : 'Bearer $llave'),
            },
            body: jsonEncode(cuerpo),
          )
          .timeout(_espera);

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
    try {
      final respuesta = await _enviar('/cuenta/codigo', {'celular': celular});
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
  Future<ResultadoVerificacion> verificar(String celular, String codigo) async {
    if (!await _hayConexion()) return ResultadoVerificacion.sinSenal;
    final usuario = await _a.usuario();
    final http.Response respuesta;
    try {
      respuesta = await _enviar('/cuenta/verificar', {
        'celular': celular,
        'codigo': codigo,
        'usuarioId': usuario.id,
      });
    } on TimeoutException {
      return ResultadoVerificacion.sinSenal;
    } on http.ClientException {
      return ResultadoVerificacion.sinSenal;
    }
    final cuerpo = _cuerpo(respuesta);
    switch (respuesta.statusCode) {
      case 200:
        if (cuerpo['cuentaExistente'] == true) {
          return ResultadoVerificacion.otraCuenta;
        }
        await _llavero.guardar(cuerpo['llave']! as String);
        await _a.guardarAjuste(AccesoLocal.claveCuentaVerificada, celular);
        // Lo anotado antes de la cuenta queda por subir.
        await _base
            .update(_base.movimientos)
            .write(
              const MovimientosCompanion(
                estadoSincronizacion: Value(EstadoSincronizacion.porSubir),
              ),
            );
        return ResultadoVerificacion.verificado;
      case 400:
        return cuerpo['error'] == 'codigo_vencido'
            ? ResultadoVerificacion.vencido
            : ResultadoVerificacion.incorrecto;
      case 409:
        return ResultadoVerificacion.otraCuenta;
      default:
        return ResultadoVerificacion.error;
    }
  }

  @override
  Stream<SituacionCuenta> observar() =>
      _a.cambios().asyncMap((_) => _situacion());

  Future<SituacionCuenta> _situacion() async {
    final verificado = await _a.leerAjuste(AccesoLocal.claveCuentaVerificada);
    if (verificado != null) {
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
    final llave = await _llavero.leer();
    if (llave == null) return false;
    _subiendo = true;
    try {
      final empresa = await _a.empresa();
      if (empresa == null) return false;
      final datos = await _datosParaSubir(empresa);
      final huella = await _huella();
      final respuesta = await _enviar('/datos/subir', datos, llave: llave);
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
        await _a.guardarAjuste(_claveHuellaSubida, huella);
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
  Future<bool> hayCambiosSinSubir() async {
    final porSubir =
        await (_base.select(_base.movimientos)
              ..where(
                (m) => m.estadoSincronizacion.equalsValue(
                  EstadoSincronizacion.porSubir,
                ),
              )
              ..limit(1))
            .get();
    return porSubir.isNotEmpty ||
        await _huella() != await _a.leerAjuste(_claveHuellaSubida);
  }

  Future<String> _huella() async {
    Future<int> contar(TableInfo tabla) async {
      final total = countAll();
      final consulta = _base.selectOnly(tabla)..addColumns([total]);
      return (await consulta.getSingle()).read(total)!;
    }

    final empresa = await _a.empresa();
    return [
      await contar(_base.bitacora),
      await contar(_base.movimientos),
      await contar(_base.diasCerrados),
      await contar(_base.cuentas),
      empresa?.nombre,
      empresa?.tipoNegocio.name,
      empresa?.horaCierreMinutos,
    ].join('|');
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
