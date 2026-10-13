import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../comun/isotipo.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// S00 · Bienvenida.
class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    const suave = TextStyle(
      fontFamily: Tipografia.familia,
      color: Colores.sobreMarcaSuave,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colores.marca,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colores.marca,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colores.marca,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, limites) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: limites.maxHeight - 60),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Isotipo(tamano: 72, invertido: true),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        Textos.nombreApp,
                        style: TextStyle(
                          fontFamily: Tipografia.familia,
                          fontSize: 64,
                          height: 1,
                          letterSpacing: -1.3,
                          fontWeight: FontWeight.w700,
                          color: Colores.sobreMarca,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        Textos.nombreCompleto,
                        style: suave.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 32),
                      Semantics(
                        header: true,
                        child: const Text(
                          Textos.esloganEnDosLineas,
                          style: TextStyle(
                            fontFamily: Tipografia.familia,
                            fontSize: 36,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: Colores.sobreMarca,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        Textos.bienvenidaDetalle,
                        style: suave.copyWith(fontSize: 16, height: 1.5),
                      ),
                      const Spacer(),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () => context.go(Rutas.vozPrimeraVenta),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colores.sobreMarca,
                          foregroundColor: Colores.azulOscuro,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(Textos.anotarPrimeraVenta),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Textos.sinCrearCuenta,
                        textAlign: TextAlign.center,
                        style: suave.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _avisar(context, null, Textos.demoLlega),
                              style: _estiloEnlace(conBorde: true),
                              child: const Text(Textos.verDemo),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _yaTengoCuenta(context),
                              style: _estiloEnlace(conBorde: false),
                              child: const Text(Textos.yaTengoCuenta),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _estiloEnlace({required bool conBorde}) =>
      OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colores.sobreMarca,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: conBorde
            ? const BorderSide(color: Colores.sobreMarcaSuave)
            : BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: Tipografia.textoFuerte,
      );

  Future<void> _avisar(BuildContext context, String? titulo, String texto) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: titulo == null ? null : Text(titulo),
          content: Text(texto),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(Textos.entendido),
            ),
          ],
        ),
      );

  Future<void> _yaTengoCuenta(BuildContext context) async {
    final empezar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Textos.cuentaEnTelefonoTitulo),
        content: const Text(Textos.cuentaEnTelefono),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Textos.empezar),
          ),
        ],
      ),
    );
    if (empezar == true && context.mounted) context.go(Rutas.vozPrimeraVenta);
  }
}
