import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/tarjeta.dart';
import '../../dominio/cuenta_real.dart';
import '../../dominio/equipo.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Cómo cuidamos tus datos» (entrega 83): el dueño que ya tenía cuenta
/// antes del texto de consentimiento lo acepta una vez, en el Asistente. No
/// bloquea nada; desaparece al tocar «Acepto».
class TarjetaConsentimiento extends ConsumerStatefulWidget {
  const TarjetaConsentimiento({super.key});

  @override
  ConsumerState<TarjetaConsentimiento> createState() =>
      _EstadoTarjetaConsentimiento();
}

class _EstadoTarjetaConsentimiento
    extends ConsumerState<TarjetaConsentimiento> {
  bool _enviando = false;

  Future<void> _aceptar() async {
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _enviando = true);
    final listo = await ref
        .read(servicioCuentaProvider)
        .aceptarConsentimiento();
    if (!mounted) return;
    setState(() => _enviando = false);
    if (!listo) {
      mensajes.showSnackBar(
        const SnackBar(content: Text(Textos.consentimientoSinSenal)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final aceptado = ref.watch(consentimientoAceptadoProvider).value ?? true;
    final cuenta = ref.watch(situacionCuentaProvider).value;
    final permisos = ref.watch(permisosProvider).value ?? Permisos.delDueno;
    if (aceptado ||
        cuenta?.estado != EstadoCuenta.guardada ||
        permisos.rol != Rol.dueno) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: Medidas.separacionTarjetas),
      child: Tarjeta(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              Textos.comoCuidamosTusDatos,
              style: Tipografia.tituloTarjeta,
            ),
            const SizedBox(height: 8),
            const Text(
              Textos.consentimientoDueno,
              style: Tipografia.secundario,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => ref
                    .read(abridorProvider)
                    .abrir(ref.read(enlacePrivacidadProvider)),
                child: const Text(Textos.politicaDePrivacidad),
              ),
            ),
            FilledButton(
              onPressed: _enviando ? null : _aceptar,
              child: const Text(Textos.aceptoLoAnterior),
            ),
          ],
        ),
      ),
    );
  }
}
