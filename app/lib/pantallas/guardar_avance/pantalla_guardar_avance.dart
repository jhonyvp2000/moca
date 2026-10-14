import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/icono_trazo.dart';
import '../../dominio/cuenta_real.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// S01 · Guarda tu avance. Sin la franja de Moca Plus: en la V1 no hay planes.
/// Desde la entrega 11 el código llega de verdad por SMS. También se abre
/// desde la tarjeta de la pestaña Moca ([desdeMoca]), con el celular ya
/// escrito si lo había.
class PantallaGuardarAvance extends ConsumerStatefulWidget {
  const PantallaGuardarAvance({
    super.key,
    this.celularInicial,
    this.desdeMoca = false,
  });

  final String? celularInicial;
  final bool desdeMoca;

  @override
  ConsumerState<PantallaGuardarAvance> createState() => _EstadoGuardarAvance();
}

class _EstadoGuardarAvance extends ConsumerState<PantallaGuardarAvance> {
  final _celular = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _celular.text = formatearCelular(widget.celularInicial ?? '');
  }

  @override
  void dispose() {
    _celular.dispose();
    super.dispose();
  }

  String get _digitos => _celular.text.replaceAll(' ', '');

  /// El error se muestra cuando ya se ve que el número no sirve: empieza con
  /// otra cifra que 9, o tiene 9 dígitos y no es válido.
  bool get _mostrarError =>
      _digitos.isNotEmpty &&
      (!_digitos.startsWith('9') ||
          (_digitos.length == 9 && !esCelularValido(_digitos)));

  @override
  Widget build(BuildContext context) {
    final resumen = ref.watch(resumenPrimerDiaProvider).value;
    final valido = esCelularValido(_digitos);

    return PantallaConAcciones(
      encabezado: widget.desdeMoca
          ? EncabezadoConVolver(
              titulo: Textos.guardaTuAvance,
              alVolver: () => context.pop(),
            )
          : null,
      rellenoSuperior: widget.desdeMoca ? 4 : 40,
      contenido: [
        if (!widget.desdeMoca) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colores.tinteAzul,
              borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colores.marca,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: IconoTrazo(
                      Icono.check,
                      color: Colores.sobreMarca,
                      grosor: 2.6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        Textos.primeraVentaAnotada,
                        style: Tipografia.tituloTarjeta,
                      ),
                      if (resumen != null)
                        Text(
                          Textos.hoyEntraron(
                            formatearSoles(resumen.ventaDeHoyCentimos),
                          ),
                          style: Tipografia.cifra(
                            Tipografia.textoFuerte.copyWith(
                              color: Colores.azulOscuro,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Semantics(
          header: true,
          child: Text(
            Textos.guardaTuAvance,
            style: Tipografia.tituloPantalla.copyWith(
              fontSize: 26,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          Textos.sinCorreoNiContrasena,
          style: Tipografia.secundario.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 20),
        Text(
          Textos.tuNumeroDeCelular,
          style: Tipografia.textoFuerte.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colores.superficie,
                borderRadius: BorderRadius.circular(Medidas.radioBoton),
                border: Border.all(color: Colores.bordeCampo),
              ),
              child: Text(Textos.prefijoPeru, style: _estiloCelular),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _celular,
                autofocus: widget.celularInicial == null,
                keyboardType: TextInputType.phone,
                inputFormatters: [_FormateadorCelular()],
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: valido ? (_) => _enviarCodigo() : null,
                style: Tipografia.cifra(_estiloCelular),
                decoration: InputDecoration(
                  hintText: Textos.celularEjemplo,
                  hintStyle: _estiloCelular.copyWith(
                    color: Colores.textoSecundario,
                    fontWeight: FontWeight.w400,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  border: _borde(Colores.bordeCampo, 1),
                  enabledBorder: _borde(
                    _mostrarError ? Colores.avisoMarca : Colores.bordeCampo,
                    1,
                  ),
                  focusedBorder: _borde(
                    _mostrarError ? Colores.avisoMarca : Colores.marca,
                    2,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_mostrarError) ...[
          const SizedBox(height: 8),
          const TextoError(Textos.celularInvalido),
        ],
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Aviso(texto: error),
        ],
      ],
      acciones: [
        FilledButton(
          onPressed: valido && !_enviando ? _enviarCodigo : null,
          child: Text(_enviando ? Textos.enviando : Textos.enviarmeCodigo),
        ),
        BotonTexto(
          texto: Textos.ahoraNo,
          alTocar: widget.desdeMoca
              ? () => context.pop()
              : () => ref.read(repositorioPrimerDiaProvider).seguirSinCuenta(),
        ),
      ],
    );
  }

  Future<void> _enviarCodigo() async {
    final celular = _digitos;
    setState(() {
      _enviando = true;
      _error = null;
    });
    final resultado = await ref
        .read(servicioCuentaProvider)
        .pedirCodigo(celular);
    if (!mounted) return;
    setState(() => _enviando = false);
    switch (resultado) {
      case ResultadoPedido.enviado:
        context.push(
          widget.desdeMoca ? Rutas.cuentaCodigo : Rutas.codigo,
          extra: celular,
        );
      case ResultadoPedido.sinSenal:
        setState(() => _error = Textos.necesitasSenalParaGuardar);
      case ResultadoPedido.demasiados:
        setState(() => _error = Textos.demasiadosCodigos);
      case ResultadoPedido.invalido:
        setState(() => _error = Textos.celularInvalido);
      case ResultadoPedido.error:
        setState(() => _error = Textos.noPudimosEnviar);
    }
  }

  static const _estiloCelular = TextStyle(
    fontFamily: Tipografia.familia,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colores.textoPrincipal,
  );

  static OutlineInputBorder _borde(Color color, double grosor) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Medidas.radioBoton),
        borderSide: BorderSide(color: color, width: grosor),
      );
}

/// Solo dígitos, hasta 9, agrupados de a tres: «987 654 321».
class _FormateadorCelular extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    var digitos = nuevo.text.replaceAll(RegExp(r'[^0-9]'), '');
    // Si pega el número con el prefijo del país, se quita.
    if (digitos.length > 9 && digitos.startsWith('51')) {
      digitos = digitos.substring(2);
    }
    if (digitos.length > 9) digitos = digitos.substring(0, 9);
    final texto = formatearCelular(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
