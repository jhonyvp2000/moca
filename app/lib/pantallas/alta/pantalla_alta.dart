import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../comun/campo_monto.dart';
import '../../comun/estructura.dart';
import '../../comun/opciones.dart';
import '../../dominio/modelos.dart';
import '../../dominio/primer_dia.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// S02 · Alta inicial. Sin botón «volver»: la venta ya está guardada y el
/// camino no retrocede.
class PantallaAlta extends ConsumerStatefulWidget {
  const PantallaAlta({super.key});

  @override
  ConsumerState<PantallaAlta> createState() => _EstadoAlta();
}

class _EstadoAlta extends ConsumerState<PantallaAlta> {
  final _nombre = TextEditingController();
  final _efectivo = TextEditingController();
  final _yape = TextEditingController();
  final _banco = TextEditingController();
  final _nombreOtra = TextEditingController();
  final _nombreOtroBanco = TextEditingController();

  /// Las billeteras y los bancos que usa además de Yape y el BCP.
  final _billeteras = <TipoCuenta>{};
  final _saldoBilletera = {
    for (final b in TipoCuenta.agregables) b: TextEditingController(),
  };
  TipoNegocio? _tipo;
  int _horaCierreMinutos = 21 * 60;
  bool _guardando = false;

  static const _billeterasOpciones = {
    TipoCuenta.plin: Textos.plin,
    TipoCuenta.bbvaPlin: Textos.bbvaPlin,
    TipoCuenta.scotiabankPlin: Textos.scotiabankPlin,
    TipoCuenta.sip: Textos.sip,
    TipoCuenta.otra: Textos.otra,
  };

  static const _bancosOpciones = {
    TipoCuenta.interbank: Textos.interbank,
    TipoCuenta.bbva: Textos.bbva,
    TipoCuenta.scotiabank: Textos.scotiabank,
    TipoCuenta.otroBanco: Textos.otroBanco,
  };

  static const _tipos = {
    TipoNegocio.bodega: Textos.bodega,
    TipoNegocio.restaurante: Textos.restaurante,
    TipoNegocio.servicios: Textos.servicios,
    TipoNegocio.otro: Textos.otro,
  };

  @override
  void dispose() {
    _nombre.dispose();
    _efectivo.dispose();
    _yape.dispose();
    _banco.dispose();
    _nombreOtra.dispose();
    _nombreOtroBanco.dispose();
    for (final c in _saldoBilletera.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _completo =>
      _nombre.text.trim().isNotEmpty &&
      _tipo != null &&
      (!_billeteras.contains(TipoCuenta.otra) ||
          _nombreOtra.text.trim().isNotEmpty) &&
      (!_billeteras.contains(TipoCuenta.otroBanco) ||
          _nombreOtroBanco.text.trim().isNotEmpty);

  String _nombreBilletera(TipoCuenta tipo) => switch (tipo) {
    TipoCuenta.otra => _nombreOtra.text.trim(),
    TipoCuenta.otroBanco => _nombreOtroBanco.text.trim(),
    _ => Textos.nombreCuenta(tipo),
  };

  /// El nombre en la fila del saldo, aunque todavía no lo haya escrito.
  String _etiquetaSaldo(TipoCuenta tipo) => switch (_nombreBilletera(tipo)) {
    '' when tipo == TipoCuenta.otra => Textos.otraBilletera,
    '' => Textos.otroBanco,
    final nombre => nombre,
  };

  Future<void> _terminar({required bool conSaldo}) async {
    if (!_completo || _guardando) return;
    setState(() => _guardando = true);
    try {
      await ref
          .read(repositorioPrimerDiaProvider)
          .completarAlta(
            DatosAlta(
              nombre: _nombre.text,
              tipoNegocio: _tipo!,
              // Un campo vacío cuenta como S/ 0.
              saldos: conSaldo
                  ? {
                      TipoCuenta.efectivo:
                          leerSolesEnCentimos(_efectivo.text) ?? 0,
                      TipoCuenta.yape: leerSolesEnCentimos(_yape.text) ?? 0,
                      TipoCuenta.banco: leerSolesEnCentimos(_banco.text) ?? 0,
                      for (final b in _billeteras)
                        b: leerSolesEnCentimos(_saldoBilletera[b]!.text) ?? 0,
                    }
                  : null,
              horaCierreMinutos: _horaCierreMinutos,
              billeteras: {
                for (final b in TipoCuenta.agregables)
                  if (_billeteras.contains(b)) b: _nombreBilletera(b),
              },
            ),
          );
      // Al terminar, la app pasa sola al Inicio.
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _elegirHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _horaCierreMinutos ~/ 60,
        minute: _horaCierreMinutos % 60,
      ),
      helpText: Textos.aQueHoraCierras,
    );
    if (hora != null) {
      setState(() => _horaCierreMinutos = hora.hour * 60 + hora.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    const etiqueta = TextStyle(
      fontFamily: Tipografia.familia,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colores.textoPrincipal,
    );

    return PantallaConAcciones(
      encabezado: const EncabezadoConVolver(titulo: Textos.unMinutoYListo),
      contenido: [
        Semantics(
          header: true,
          child: Text(
            Textos.cuentaleDeTuNegocio,
            style: Tipografia.tituloPantalla.copyWith(fontSize: 24),
          ),
        ),
        const SizedBox(height: 18),
        const Text(Textos.comoSeLlama, style: etiqueta),
        const SizedBox(height: 8),
        TextField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          style: Tipografia.textoFuerte.copyWith(fontSize: 16),
          decoration: InputDecoration(
            hintText: Textos.nombreEjemplo,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: _borde(Colores.bordeCampo, 1),
            enabledBorder: _borde(Colores.bordeCampo, 1),
            focusedBorder: _borde(Colores.marca, 2),
          ),
        ),
        const SizedBox(height: 18),
        const Text(Textos.queTipoDeNegocio, style: etiqueta),
        const SizedBox(height: 8),
        Opciones<TipoNegocio>(
          opciones: _tipos,
          elegida: _tipo,
          alElegir: (tipo) => setState(() => _tipo = tipo),
        ),
        const SizedBox(height: 18),
        const Text(Textos.usasOtraBilletera, style: etiqueta),
        const SizedBox(height: 4),
        const Text(Textos.puedesAgregarlaDespues, style: Tipografia.secundario),
        const SizedBox(height: 8),
        OpcionesVarias<TipoCuenta>(
          opciones: _billeterasOpciones,
          elegidas: _billeteras,
          alTocar: (b) => setState(
            () => _billeteras.contains(b)
                ? _billeteras.remove(b)
                : _billeteras.add(b),
          ),
        ),
        if (_billeteras.contains(TipoCuenta.otra))
          _campoNombre(
            const Key('nombre-otra-billetera'),
            _nombreOtra,
            Textos.nombreDeLaBilletera,
          ),
        const SizedBox(height: 18),
        const Text(Textos.usasOtroBanco, style: etiqueta),
        const SizedBox(height: 4),
        const Text(Textos.puedesAgregarlaDespues, style: Tipografia.secundario),
        const SizedBox(height: 8),
        OpcionesVarias<TipoCuenta>(
          opciones: _bancosOpciones,
          elegidas: _billeteras,
          alTocar: (b) => setState(
            () => _billeteras.contains(b)
                ? _billeteras.remove(b)
                : _billeteras.add(b),
          ),
        ),
        if (_billeteras.contains(TipoCuenta.otroBanco))
          _campoNombre(
            const Key('nombre-otro-banco'),
            _nombreOtroBanco,
            Textos.nombreDelBanco,
          ),
        const SizedBox(height: 18),
        const Text(Textos.cuantaPlataTienes, style: etiqueta),
        const SizedBox(height: 4),
        const Text(Textos.sinContarLaVenta, style: Tipografia.secundario),
        const SizedBox(height: 10),
        GrupoMontos(
          filas: [
            FilaMonto(etiqueta: Textos.efectivo, controlador: _efectivo),
            FilaMonto(etiqueta: Textos.yape, controlador: _yape),
            for (final b in TipoCuenta.billeteras)
              if (_billeteras.contains(b))
                FilaMonto(
                  etiqueta: _etiquetaSaldo(b),
                  controlador: _saldoBilletera[b]!,
                ),
            FilaMonto(
              etiqueta: Textos.banco,
              controlador: _banco,
              accionTeclado: _billeteras.any((b) => b.esBanco)
                  ? TextInputAction.next
                  : TextInputAction.done,
            ),
            for (final b in TipoCuenta.otrosBancos)
              if (_billeteras.contains(b))
                FilaMonto(
                  etiqueta: _etiquetaSaldo(b),
                  controlador: _saldoBilletera[b]!,
                ),
          ],
        ),
        const SizedBox(height: 18),
        Material(
          color: Colores.superficie,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
            side: const BorderSide(color: Colores.bordeTarjeta),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
            onTap: _elegirHora,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Textos.aQueHoraCierras, style: etiqueta),
                        Text(
                          Textos.mocaRecuerdaVenta,
                          style: Tipografia.secundario,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: Medidas.altoCampo,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Medidas.radioCampo),
                      border: Border.all(color: Colores.bordeCampo),
                    ),
                    child: Text(
                      formatearHora(_horaCierreMinutos),
                      style: Tipografia.cifra(
                        Tipografia.textoFuerte.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(Textos.textoLegalAlta, style: Tipografia.secundario),
      ],
      acciones: [
        FilledButton(
          onPressed: _completo && !_guardando
              ? () => _terminar(conSaldo: true)
              : null,
          child: const Text(Textos.listoEmpezar),
        ),
        BotonTexto(
          texto: Textos.noSeCuantoTengo,
          alTocar: _completo && !_guardando
              ? () => _terminar(conSaldo: false)
              : null,
        ),
      ],
    );
  }

  /// El nombre de la otra billetera o del otro banco.
  Widget _campoNombre(Key key, TextEditingController c, String ayuda) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextField(
          key: key,
          controller: c,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          style: Tipografia.textoFuerte.copyWith(fontSize: 16),
          decoration: InputDecoration(
            hintText: ayuda,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: _borde(Colores.bordeCampo, 1),
            enabledBorder: _borde(Colores.bordeCampo, 1),
            focusedBorder: _borde(Colores.marca, 2),
          ),
        ),
      );

  static OutlineInputBorder _borde(Color color, double grosor) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Medidas.radioBoton),
        borderSide: BorderSide(color: color, width: grosor),
      );
}
