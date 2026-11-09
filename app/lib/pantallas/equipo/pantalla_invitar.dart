import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/opciones.dart';
import '../../dominio/cobro.dart';
import '../../dominio/equipo.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import 'invitacion_whatsapp.dart';

/// Invitar a alguien al negocio (entrega 19): nombre, celular y rol. Solo
/// los dueños llegan aquí. La persona entra con su número en «Me invitaron».
class PantallaInvitar extends ConsumerStatefulWidget {
  const PantallaInvitar({super.key, this.equipo});

  /// El equipo de hoy: si la persona pasa de las que incluye el plan, se
  /// avisa que se cobra aparte (entrega 43).
  final Equipo? equipo;

  @override
  ConsumerState<PantallaInvitar> createState() => _EstadoInvitar();
}

class _EstadoInvitar extends ConsumerState<PantallaInvitar> {
  final _nombre = TextEditingController();
  final _celular = TextEditingController();
  Rol _rol = Rol.ayudante;
  bool _enviando = false;
  String? _error;

  /// Ya invitada: el aviso y «Mandarle la invitación por WhatsApp»
  /// (entrega 30). Vale 7 días, como en el servidor.
  DateTime? _venceEn;

  @override
  void dispose() {
    _nombre.dispose();
    _celular.dispose();
    super.dispose();
  }

  String get _digitos => _celular.text.replaceAll(' ', '');

  /// Antes de invitar a alguien que pasa de las que incluye el plan.
  Future<bool> _seCobraAparte() async {
    final equipo = widget.equipo;
    final cobro = ref.read(cobroProvider).value ?? Cobro.sinCobro;
    if (equipo == null ||
        _rol == Rol.contador ||
        !equipo.siguienteSeCobra ||
        cobro.estado == EstadoDelCobro.sinCobro) {
      return true;
    }
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(Textos.personaExtraTitulo),
            content: Text(
              Textos.personaExtraDetalle(equipo.incluidas),
              style: Tipografia.texto,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(Textos.cancelar),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(Textos.invitarIgual),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _invitar() async {
    if (!await _seCobraAparte() || !mounted) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    final nombre = _nombre.text.trim();
    final resultado = await ref
        .read(servicioEquipoProvider)
        .invitar(celular: _digitos, rol: _rol, nombre: nombre);
    if (!mounted) return;
    if (resultado == ResultadoEquipo.listo) {
      setState(() {
        _enviando = false;
        _venceEn = ref.read(relojProvider)().add(const Duration(days: 7));
      });
      return;
    }
    setState(() {
      _enviando = false;
      _error = switch (resultado) {
        ResultadoEquipo.sinSenal => Textos.necesitasSenalParaEquipo,
        ResultadoEquipo.sinLugar => Textos.sinLugar,
        ResultadoEquipo.yaEsta => Textos.yaEstaEnElNegocio,
        ResultadoEquipo.sinPermiso => Textos.soloLosDuenos,
        _ => Textos.noPudimosEnviar,
      };
    });
  }

  Widget _invitada(DateTime venceEn) {
    final nombre = _nombre.text.trim();
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.invitarAAlguien,
        alVolver: () => context.pop(true),
      ),
      contenido: [
        Aviso(
          texto: Textos.invitacionEnviada(
            nombre.isEmpty ? formatearCelular(_digitos) : nombre,
          ),
        ),
      ],
      acciones: [
        FilledButton(
          onPressed: () => mandarInvitacionPorWhatsApp(
            context,
            ref,
            celular: _digitos,
            rol: _rol,
            venceEn: venceEn,
            nombre: nombre,
          ),
          child: const Text(Textos.mandarInvitacionWhatsApp),
        ),
        OutlinedButton(
          onPressed: () => context.pop(true),
          child: const Text(Textos.listoInvitar),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_venceEn case final venceEn?) return _invitada(venceEn);
    final valido = esCelularValido(_digitos);
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.invitarAAlguien,
        alVolver: () => context.pop(),
      ),
      contenido: [
        const Text(Textos.nombreDeLaPersona, style: Tipografia.textoFuerte),
        const SizedBox(height: 8),
        TextField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
          decoration: const InputDecoration(
            hintText: Textos.nombrePersonaEjemplo,
          ),
        ),
        const SizedBox(height: 16),
        const Text(Textos.suNumero, style: Tipografia.textoFuerte),
        const SizedBox(height: 8),
        TextField(
          controller: _celular,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          onChanged: (_) => setState(() => _error = null),
          decoration: const InputDecoration(
            prefixText: '${Textos.prefijoPeru} ',
            hintText: Textos.celularEjemplo,
          ),
        ),
        if (_digitos.length == 9 && !valido) ...[
          const SizedBox(height: 8),
          const TextoError(Textos.celularInvalido),
        ],
        const SizedBox(height: 16),
        const Text(Textos.queHaraEnTuNegocio, style: Tipografia.textoFuerte),
        const SizedBox(height: 8),
        Opciones<Rol>(
          opciones: {for (final r in Rol.values) r: Textos.nombreRol(r)},
          elegida: _rol,
          alElegir: (r) => setState(() => _rol = r),
        ),
        const SizedBox(height: 8),
        Text(Textos.detalleRol(_rol), style: Tipografia.secundario),
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Aviso(texto: error),
        ],
      ],
      acciones: [
        FilledButton(
          onPressed: valido && !_enviando ? _invitar : null,
          child: Text(_enviando ? Textos.invitando : Textos.enviarInvitacion),
        ),
      ],
    );
  }
}
