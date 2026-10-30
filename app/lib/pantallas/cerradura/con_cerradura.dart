import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/isotipo.dart';
import '../../inyeccion.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Pedir huella al abrir Moca» (entrega 16.3): al abrir la app, y al volver
/// después de un rato fuera, tapa todo hasta que la persona pase el bloqueo
/// de su teléfono. Debajo, la app sigue en la misma pantalla.
class ConCerradura extends ConsumerStatefulWidget {
  const ConCerradura({super.key, required this.child});

  /// Cuánto puede estar fuera de Moca sin que pida la huella al volver.
  /// 30 segundos para las pruebas; el tiempo final queda en pendientes.md.
  static const esperaParaPedirla = Duration(seconds: 30);

  final Widget child;

  @override
  ConsumerState<ConCerradura> createState() => _EstadoCerradura();
}

class _EstadoCerradura extends ConsumerState<ConCerradura>
    with WidgetsBindingObserver {
  /// Al abrir, tapada hasta saber si este teléfono pide la huella.
  bool _cerrada = true;
  bool _supoAlAbrir = false;
  bool _verificando = false;
  DateTime? _salioEn;

  bool get _pideHuella => ref.read(pedirHuellaProvider).value ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(pedirHuellaProvider, (_, pide) {
      final valor = pide.value;
      if (valor == null) return;
      if (!_supoAlAbrir) {
        _supoAlAbrir = true;
        setState(() => _cerrada = valor);
        if (valor) _verificar();
      } else if (!valor && _cerrada) {
        setState(() => _cerrada = false);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    // La ventana del PIN del teléfono también saca a Moca de la vista: eso
    // no cuenta como salir.
    if (_verificando) return;
    switch (estado) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        _salioEn ??= ref.read(relojProvider)();
      case AppLifecycleState.resumed:
        final salio = _salioEn;
        _salioEn = null;
        if (salio == null || _cerrada || !_pideHuella) return;
        final fuera = ref.read(relojProvider)().difference(salio);
        if (fuera > ConCerradura.esperaParaPedirla) {
          setState(() => _cerrada = true);
          _verificar();
        }
      default:
    }
  }

  Future<void> _verificar() async {
    if (_verificando) return;
    _verificando = true;
    try {
      final paso = await ref
          .read(cerraduraProvider)
          .verificar(Textos.confirmaQueEresTu);
      if (paso && mounted) setState(() => _cerrada = false);
    } finally {
      _verificando = false;
      _salioEn = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_cerrada)
          Positioned.fill(
            child: _PantallaCerrada(
              // Hasta saber si pide la huella, solo el logo.
              alUsarHuella: _supoAlAbrir ? _verificar : null,
            ),
          ),
      ],
    );
  }
}

/// Solo el logo y «Usar huella»: ni cifras ni el nombre del negocio.
class _PantallaCerrada extends StatelessWidget {
  const _PantallaCerrada({required this.alUsarHuella});

  final VoidCallback? alUsarHuella;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colores.fondo,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Medidas.margenLateral),
          child: Column(
            children: [
              const Spacer(),
              const Isotipo(tamano: 72),
              if (alUsarHuella != null) ...[
                const SizedBox(height: 20),
                const Text(
                  Textos.mocaProtegida,
                  style: Tipografia.tituloPantalla,
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              if (alUsarHuella != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: alUsarHuella,
                    child: const Text(Textos.usarHuella),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
