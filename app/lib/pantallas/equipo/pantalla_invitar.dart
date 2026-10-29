import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/opciones.dart';
import '../../dominio/equipo.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// Invitar a alguien al negocio (entrega 19): nombre, celular y rol. Solo
/// los dueños llegan aquí. La persona entra con su número en «Me invitaron».
class PantallaInvitar extends ConsumerStatefulWidget {
  const PantallaInvitar({super.key});

  @override
  ConsumerState<PantallaInvitar> createState() => _EstadoInvitar();
}

class _EstadoInvitar extends ConsumerState<PantallaInvitar> {
  final _nombre = TextEditingController();
  final _celular = TextEditingController();
  Rol _rol = Rol.ayudante;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _celular.dispose();
    super.dispose();
  }

  String get _digitos => _celular.text.replaceAll(' ', '');

  Future<void> _invitar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    final mensajes = ScaffoldMessenger.of(context);
    final nombre = _nombre.text.trim();
    final resultado = await ref
        .read(servicioEquipoProvider)
        .invitar(celular: _digitos, rol: _rol, nombre: nombre);
    if (!mounted) return;
    if (resultado == ResultadoEquipo.listo) {
      mensajes.showSnackBar(
        SnackBar(
          content: Text(
            Textos.invitacionEnviada(
              nombre.isEmpty ? formatearCelular(_digitos) : nombre,
            ),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      context.pop(true);
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

  @override
  Widget build(BuildContext context) {
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
