import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/cuenta_real.dart';
import '../../dominio/medicion.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import 'modo_cuenta.dart';

/// Código de acceso (estado no dibujado, aprobado el 12-10-2026). Desde la
/// entrega 11 el código llega por SMS y lo comprueba el servidor; al
/// verificarlo se sube lo anotado (estados aprobados el 14-10-2026).
class PantallaCodigo extends ConsumerStatefulWidget {
  const PantallaCodigo({
    super.key,
    required this.celular,
    this.modo = ModoCuenta.primerDia,
  });

  /// Los 9 dígitos, sin espacios.
  final String celular;

  /// Desde la tarjeta de Moca vuelve a Moca al terminar; para entrar
  /// («Ya tengo cuenta») baja los datos de la cuenta.
  final ModoCuenta modo;

  /// Segundos antes de poder pedir otro código.
  static const esperaParaReenviar = 30;

  @override
  ConsumerState<PantallaCodigo> createState() => _EstadoCodigo();
}

enum _Fase {
  escribiendo,
  comprobando,
  guardando,

  /// «Ya tengo cuenta» (entrega 12).
  bajando,
  bajadaFallida,
  sinCuenta,

  /// «Me invitaron» con un número sin invitación (entrega 19).
  sinInvitacion,

  /// El número ya tiene cuenta y este teléfono tiene datos (entrega 14.4).
  cuentaExistente,
  juntando,
  juntadaFallida,
}

class _EstadoCodigo extends ConsumerState<PantallaCodigo> {
  final _codigo = TextEditingController();
  _Fase _fase = _Fase.escribiendo;
  String? _error;
  String? _nota;
  int _faltan = PantallaCodigo.esperaParaReenviar;
  Timer? _reloj;

  /// El SMS del código, leído por Android (entrega 14.7).
  late final LectorCodigoSms _lectorSms;
  StreamSubscription<String>? _sms;
  bool _leeSms = false;
  bool _delSms = false;

  @override
  void initState() {
    super.initState();
    _contarParaReenviar();
    _lectorSms = ref.read(lectorCodigoSmsProvider);
    _sms = _lectorSms.codigos.listen(_codigoDelSms);
    _lectorSms.marca().then((marca) {
      if (mounted && marca != null) setState(() => _leeSms = true);
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _sms?.cancel();
    _lectorSms.dejarDeEsperar();
    _codigo.dispose();
    super.dispose();
  }

  void _codigoDelSms(String codigo) {
    if (!mounted || _fase != _Fase.escribiendo) return;
    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) return;
    _codigo.text = codigo;
    _delSms = true;
    _confirmar();
  }

  void _contarParaReenviar() {
    _reloj?.cancel();
    setState(() => _faltan = PantallaCodigo.esperaParaReenviar);
    _reloj = Timer.periodic(const Duration(seconds: 1), (reloj) {
      if (!mounted) return reloj.cancel();
      setState(() => _faltan--);
      if (_faltan <= 0) reloj.cancel();
    });
  }

  bool get _completo => _codigo.text.length == 6;

  Future<void> _reenviar({String? nota}) async {
    final resultado = await ref
        .read(servicioCuentaProvider)
        .pedirCodigo(widget.celular);
    if (!mounted) return;
    setState(() {
      _error = switch (resultado) {
        ResultadoPedido.enviado => null,
        ResultadoPedido.sinSenal => Textos.necesitasSenalParaGuardar,
        ResultadoPedido.demasiados => Textos.demasiadosCodigos,
        _ => Textos.noPudimosEnviar,
      };
      _nota = resultado == ResultadoPedido.enviado
          ? nota ?? Textos.codigoReenviado
          : null;
    });
    if (resultado == ResultadoPedido.enviado) _contarParaReenviar();
  }

  Future<void> _confirmar() async {
    if (!_completo || _fase != _Fase.escribiendo) return;
    setState(() {
      _fase = _Fase.comprobando;
      _error = null;
      _nota = _delSms ? Textos.codigoLeidoDelSms : null;
    });
    ref.read(medicionProvider).anotar(EventoMedicion.codigoComprobado, {
      'delSms': _delSms,
    });
    _delSms = false;
    final servicio = ref.read(servicioCuentaProvider);
    final resultado = await servicio.verificar(
      widget.celular,
      _codigo.text,
      entrar: widget.modo == ModoCuenta.entrar,
      invitado: _invitado,
    );
    if (!mounted) return;
    if (resultado == ResultadoVerificacion.sinCuenta) {
      setState(() => _fase = _Fase.sinCuenta);
      return;
    }
    if (resultado == ResultadoVerificacion.sinInvitacion) {
      setState(() {
        _fase = _Fase.sinInvitacion;
        _codigo.clear();
      });
      return;
    }
    if (resultado == ResultadoVerificacion.otraCuenta) {
      setState(() => _fase = _Fase.cuentaExistente);
      return;
    }
    if (resultado != ResultadoVerificacion.verificado) {
      setState(() {
        _fase = _Fase.escribiendo;
        _codigo.clear();
        _error = switch (resultado) {
          ResultadoVerificacion.incorrecto => Textos.codigoIncorrecto,
          ResultadoVerificacion.sinSenal =>
            _entrar
                ? Textos.necesitasSenalParaEntrar
                : Textos.necesitasSenalParaGuardar,
          _ => Textos.noPudimosComprobar,
        };
      });
      // Un código vencido se reemplaza solo.
      if (resultado == ResultadoVerificacion.vencido) {
        setState(() => _error = null);
        await _reenviar(nota: Textos.codigoVencido);
      }
      return;
    }
    // El invitado ve su invitación y la acepta (entrega 19).
    if (_invitado) {
      context.push(Rutas.invitadoAceptar);
      setState(() {
        _fase = _Fase.escribiendo;
        _codigo.clear();
      });
      return;
    }
    if (_entrar) return _bajar();
    await _guardar();
  }

  /// Con el número verificado en este teléfono: sube lo anotado y sigue.
  Future<void> _guardar() async {
    final servicio = ref.read(servicioCuentaProvider);
    setState(() => _fase = _Fase.guardando);
    // Si se corta la señal, lo que falta se sube después solo.
    await servicio.subirTodo();
    if (!mounted) return;
    final mensajes = ScaffoldMessenger.of(context);
    await ref.read(repositorioPrimerDiaProvider).guardarCelular(widget.celular);
    // Desde el primer día, la app pasa sola al alta.
    if (widget.modo == ModoCuenta.desdeMoca && mounted) {
      context.go(Rutas.moca);
      mensajes.showSnackBar(
        const SnackBar(content: Text(Textos.avanceGuardado)),
      );
    }
  }

  bool get _entrar =>
      widget.modo == ModoCuenta.entrar || widget.modo == ModoCuenta.invitado;
  bool get _invitado => widget.modo == ModoCuenta.invitado;

  bool get _conCuentaExistente => const {
    _Fase.cuentaExistente,
    _Fase.juntando,
    _Fase.juntadaFallida,
  }.contains(_fase);

  /// «Entrar a mi cuenta»: baja la cuenta y le suma lo de este teléfono.
  Future<void> _entrarYSumar() async {
    setState(() => _fase = _Fase.juntando);
    final mensajes = ScaffoldMessenger.of(context);
    final resultado = await ref.read(servicioCuentaProvider).entrarYSumar();
    if (!mounted) return;
    switch (resultado) {
      case ResultadoBajada.listo:
        context.go(Rutas.inicio);
        mensajes.showSnackBar(
          const SnackBar(content: Text(Textos.yaEstanJuntos)),
        );
      case ResultadoBajada.vencido:
        _volverAPedir();
      case ResultadoBajada.sinSenal || ResultadoBajada.error:
        setState(() => _fase = _Fase.juntadaFallida);
    }
  }

  /// «Empezar de cero»: después de confirmarlo, la cuenta anterior se
  /// archiva y este teléfono sigue como una cuenta nueva.
  Future<void> _empezarDeCero() async {
    final si = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text(Textos.empezarDeCeroPregunta),
        content: const Text(Textos.empezarDeCeroDetalle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text(Textos.empezarDeCeroSi),
          ),
        ],
      ),
    );
    if (si != true || !mounted) return;
    setState(() => _fase = _Fase.guardando);
    final resultado = await ref.read(servicioCuentaProvider).empezarDeCero();
    if (!mounted) return;
    switch (resultado) {
      case ResultadoVerificacion.verificado:
        await _guardar();
      case ResultadoVerificacion.vencido:
        _volverAPedir();
      default:
        setState(() {
          _fase = _Fase.cuentaExistente;
          _error = resultado == ResultadoVerificacion.sinSenal
              ? Textos.necesitasSenalParaGuardar
              : Textos.noPudimosComprobar;
        });
    }
  }

  /// «Seguir sin cuenta»: lo anotado queda solo en este teléfono.
  void _seguirSinCuenta() => widget.modo == ModoCuenta.primerDia
      ? ref.read(repositorioPrimerDiaProvider).seguirSinCuenta()
      : context.go(Rutas.moca);

  /// El pase venció: a escribir un código nuevo.
  void _volverAPedir() => setState(() {
    _fase = _Fase.escribiendo;
    _codigo.clear();
    _error = Textos.pasoMuchoTiempo;
  });

  /// Baja todo lo de la cuenta. Al terminar, la app pasa sola al Inicio.
  Future<void> _bajar() async {
    setState(() => _fase = _Fase.bajando);
    final mensajes = ScaffoldMessenger.of(context);
    final resultado = await ref.read(servicioCuentaProvider).bajarTodo();
    if (resultado == ResultadoBajada.listo) {
      mensajes.showSnackBar(const SnackBar(content: Text(Textos.yaTienesTodo)));
      return;
    }
    if (mounted) setState(() => _fase = _Fase.bajadaFallida);
  }

  @override
  Widget build(BuildContext context) {
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: switch (widget.modo) {
          ModoCuenta.entrar => Textos.entraATuCuenta,
          ModoCuenta.invitado => Textos.entraAlNegocio,
          _ => Textos.guardaTuAvance,
        },
        alVolver: () => context.pop(),
      ),
      contenido: [
        Semantics(
          header: true,
          child: Text(
            _conCuentaExistente
                ? Textos.numeroConCuenta
                : Textos.escribeElCodigo,
            style: Tipografia.tituloPantalla.copyWith(fontSize: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          Textos.codigoEnviadoA(formatearCelular(widget.celular)),
          style: Tipografia.secundario.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _codigo,
          autofocus: true,
          enabled: _fase == _Fase.escribiendo,
          keyboardType: TextInputType.number,
          // Si Android no lo lee solo, el teclado puede sugerirlo.
          autofillHints: const [AutofillHints.oneTimeCode],
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (_) {
            setState(() => _error = null);
            if (_completo) _confirmar();
          },
          style: Tipografia.cifra(
            const TextStyle(
              fontFamily: Tipografia.familia,
              fontSize: 28,
              letterSpacing: 12,
              fontWeight: FontWeight.w700,
              color: Colores.textoPrincipal,
            ),
          ),
          decoration: const InputDecoration(
            hintText: '······',
            labelText: Textos.codigo,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (_leeSms &&
            _fase == _Fase.escribiendo &&
            _codigo.text.isEmpty &&
            _error == null) ...[
          const SizedBox(height: 8),
          const Text(Textos.esperandoSms, style: Tipografia.secundario),
        ],
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Aviso(texto: error),
        ],
        if (_fase == _Fase.sinCuenta) ...[
          const SizedBox(height: 12),
          const Aviso(texto: Textos.numeroSinCuenta),
        ],
        if (_fase == _Fase.sinInvitacion) ...[
          const SizedBox(height: 12),
          const Aviso(texto: Textos.sinInvitacion),
        ],
        if (_conCuentaExistente) ...[
          const SizedBox(height: 16),
          const TarjetaMoca(texto: Textos.numeroConCuentaDetalle),
        ],
        if (_fase == _Fase.juntadaFallida) ...[
          const SizedBox(height: 12),
          const Aviso(texto: Textos.seCortoLaSenal),
        ],
        if (_fase == _Fase.bajadaFallida) ...[
          const SizedBox(height: 12),
          const Aviso(texto: Textos.seCortoLaSenal),
        ],
        if (_nota case final nota?) ...[
          const SizedBox(height: 12),
          Text(nota, style: Tipografia.secundario),
        ],
        Wrap(
          children: [
            TextButton(
              onPressed: _fase == _Fase.escribiendo && _faltan <= 0
                  ? _reenviar
                  : null,
              child: Text(
                _faltan > 0
                    ? Textos.reenviarEn(_faltan)
                    : Textos.reenviarCodigo,
              ),
            ),
            TextButton(
              onPressed: _fase == _Fase.escribiendo
                  ? () => context.pop()
                  : null,
              child: const Text(Textos.cambiarNumero),
            ),
          ],
        ),
      ],
      acciones: [
        FilledButton(
          onPressed: switch (_fase) {
            _Fase.escribiendo => _completo ? _confirmar : null,
            _Fase.sinCuenta => () => context.go(Rutas.vozPrimeraVenta),
            _Fase.sinInvitacion => () => context.go(Rutas.bienvenida),
            _Fase.bajadaFallida => _bajar,
            _Fase.cuentaExistente || _Fase.juntadaFallida => _entrarYSumar,
            _ => null,
          },
          child: Text(switch (_fase) {
            _Fase.escribiendo => Textos.confirmar,
            _Fase.comprobando => Textos.comprobando,
            _Fase.guardando => Textos.guardandoLoAnotado,
            _Fase.bajando => Textos.bajandoTusDatos,
            _Fase.bajadaFallida => Textos.intentarOtraVez,
            _Fase.sinCuenta => Textos.anotarMiPrimeraVenta,
            _Fase.sinInvitacion => Textos.volver,
            _Fase.cuentaExistente => Textos.entrarAMiCuenta,
            _Fase.juntando => Textos.juntandoLoAnotado,
            _Fase.juntadaFallida => Textos.intentarOtraVez,
          }),
        ),
        if (_fase case _Fase.cuentaExistente || _Fase.juntadaFallida) ...[
          OutlinedButton(
            onPressed: _empezarDeCero,
            child: const Text(Textos.empezarDeCero),
          ),
          BotonTexto(texto: Textos.seguirSinCuenta, alTocar: _seguirSinCuenta),
        ],
      ],
    );
  }
}
