import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/negocio.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import '../../tema/medidas.dart';

/// «Datos del negocio» (entrega 29.1), solo para dueños: el nombre y la
/// hora de cierre. El aviso de cierre se reprograma solo.
class PantallaDatosNegocio extends ConsumerStatefulWidget {
  const PantallaDatosNegocio({super.key});

  @override
  ConsumerState<PantallaDatosNegocio> createState() => _EstadoDatos();
}

class _EstadoDatos extends ConsumerState<PantallaDatosNegocio> {
  final _nombre = TextEditingController();
  int? _horaCierre;
  DatosDelNegocio? _antes;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    ref.read(repositorioNegocioProvider).observar().first.then((datos) {
      if (!mounted || datos == null) return;
      setState(() {
        _antes = datos;
        _nombre.text = datos.nombre;
        _horaCierre = datos.horaCierreMinutos;
      });
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  bool get _cambio =>
      _antes != null &&
      _nombre.text.trim().isNotEmpty &&
      (_nombre.text.trim() != _antes!.nombre ||
          _horaCierre != _antes!.horaCierreMinutos);

  Future<void> _elegirHora() async {
    final actual = _horaCierre ?? 21 * 60;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: actual ~/ 60, minute: actual % 60),
      helpText: Textos.aQueHoraCierras,
    );
    if (hora != null) {
      setState(() => _horaCierre = hora.hour * 60 + hora.minute);
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final mensajes = ScaffoldMessenger.of(context);
    await ref
        .read(repositorioNegocioProvider)
        .guardar(
          DatosDelNegocio(
            nombre: _nombre.text,
            horaCierreMinutos: _horaCierre!,
          ),
        );
    if (!mounted) return;
    mensajes.showSnackBar(const SnackBar(content: Text(Textos.datosGuardados)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final hora = _horaCierre;
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.datosDelNegocio,
        alVolver: () => context.pop(),
      ),
      contenido: [
        const Text(Textos.comoSeLlama, style: Tipografia.textoFuerte),
        const SizedBox(height: 8),
        TextField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Tarjeta(
          relleno: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: hora == null ? null : _elegirHora,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Medidas.e4,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Textos.aQueHoraCierras,
                            style: Tipografia.textoFuerte,
                          ),
                          Text(
                            Textos.mocaRecuerdaVenta,
                            style: Tipografia.secundario,
                          ),
                        ],
                      ),
                    ),
                    if (hora != null)
                      Text(formatearHora(hora), style: Tipografia.textoFuerte),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      acciones: [
        FilledButton(
          onPressed: _cambio && !_guardando ? _guardar : null,
          child: const Text(Textos.guardar),
        ),
      ],
    );
  }
}
