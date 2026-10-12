import 'package:flutter/material.dart';

import '../../comun/icono_trazo.dart';
import '../../comun/isotipo.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/primer_dia.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// S03 · Primer día. Es el Inicio durante la primera semana, hasta el primer
/// arqueo (prototipo-v1.md, «Comportamiento acordado»).
class PantallaPrimerDia extends StatelessWidget {
  const PantallaPrimerDia({
    super.key,
    required this.resumen,
    required this.alAnotarVenta,
    required this.alAnotarGasto,
    required this.alDeclararSaldo,
  });

  final ResumenPrimerDia resumen;
  final VoidCallback alAnotarVenta;
  final VoidCallback alAnotarGasto;
  final VoidCallback alDeclararSaldo;

  static const _ventaDiasMeta = 5;

  @override
  Widget build(BuildContext context) {
    final nota = resumen.saldoPendiente
        ? Textos.notaSaldoPendiente
        : resumen.conOtrosMovimientos
        ? Textos.notaConMovimientos
        : resumen.ventaDeHoyAnotada
        ? Textos.notaSaldoMasVenta
        : Textos.notaSoloSaldo;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.margenLateral,
              16,
              Medidas.margenLateral,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        resumen.nombreNegocio,
                        style: Tipografia.tituloTarjeta.copyWith(fontSize: 17),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(Textos.tuPrimerDia, style: Tipografia.secundario),
              ],
            ),
          ),
          _conMargen(
            Tarjeta(
              relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Textos.tienesHoy,
                    style: Tipografia.textoFuerte.copyWith(
                      color: Colores.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatearSoles(resumen.tienesHoyCentimos),
                      maxLines: 1,
                      style: Tipografia.cifra(
                        const TextStyle(
                          fontFamily: Tipografia.familia,
                          fontSize: 46,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          color: Colores.textoPrincipal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(nota, style: Tipografia.secundario),
                ],
              ),
            ),
          ),
          const SizedBox(height: Medidas.separacionTarjetas),
          _conMargen(
            _TarjetaMocaConBoton(
              texto: resumen.ventaDeHoyAnotada
                  ? Textos.mocaYaAnotaste
                  : Textos.mocaEmpiezaPorLaVenta,
              boton: resumen.ventaDeHoyAnotada
                  ? Textos.anotarUnGasto
                  : Textos.anotarVentaDeHoy,
              icono: resumen.ventaDeHoyAnotada ? Icono.mas : Icono.microfono,
              alTocar: resumen.ventaDeHoyAnotada
                  ? alAnotarGasto
                  : alAnotarVenta,
            ),
          ),
          const SizedBox(height: Medidas.separacionTarjetas),
          _conMargen(
            Tarjeta(
              relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    Textos.tusPrimerosPasos,
                    style: Tipografia.tituloTarjeta,
                  ),
                  const SizedBox(height: 4),
                  _Paso(
                    numero: 1,
                    texto: Textos.pasoDecirPlata,
                    estado: resumen.saldoPendiente
                        ? _EstadoPaso.actual
                        : _EstadoPaso.hecho,
                    alTocar: resumen.saldoPendiente ? alDeclararSaldo : null,
                  ),
                  _Paso(
                    numero: 2,
                    texto: Textos.pasoVentaCincoDias(resumen.diasConVenta),
                    estado: resumen.diasConVenta >= _ventaDiasMeta
                        ? _EstadoPaso.hecho
                        : resumen.saldoPendiente
                        ? _EstadoPaso.pendiente
                        : _EstadoPaso.actual,
                  ),
                  const _Paso(
                    numero: 3,
                    texto: Textos.pasoPrimerGasto,
                    estado: _EstadoPaso.pendiente,
                  ),
                  const _Paso(
                    numero: 4,
                    texto: Textos.pasoPrimerArqueo,
                    estado: _EstadoPaso.pendiente,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    Textos.conEstosPasos,
                    style: Tipografia.secundario,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conMargen(Widget hijo) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Medidas.margenLateral),
    child: hijo,
  );
}

class _TarjetaMocaConBoton extends StatelessWidget {
  const _TarjetaMocaConBoton({
    required this.texto,
    required this.boton,
    required this.icono,
    required this.alTocar,
  });

  final String texto;
  final String boton;
  final Icono icono;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colores.tinteAzul,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Isotipo(tamano: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      Textos.pestanaMoca,
                      style: Tipografia.etiquetaMoca,
                    ),
                    const SizedBox(height: 2),
                    Text(texto, style: Tipografia.texto),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: alTocar,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
              ),
            ),
            icon: IconoTrazo(icono, color: Colores.sobreMarca),
            label: Text(boton),
          ),
        ],
      ),
    );
  }
}

enum _EstadoPaso { hecho, actual, pendiente }

class _Paso extends StatelessWidget {
  const _Paso({
    required this.numero,
    required this.texto,
    required this.estado,
    this.alTocar,
  });

  final int numero;
  final String texto;
  final _EstadoPaso estado;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final circulo = switch (estado) {
      _EstadoPaso.hecho => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Colores.marca,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: IconoTrazo(
            Icono.check,
            color: Colores.sobreMarca,
            tamano: 16,
            grosor: 2.6,
          ),
        ),
      ),
      _ => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 2,
            color: estado == _EstadoPaso.actual
                ? Colores.marca
                : Colores.bordeBotonSecundario,
          ),
        ),
        child: Center(
          child: Text(
            '$numero',
            style: TextStyle(
              fontFamily: Tipografia.familia,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: estado == _EstadoPaso.actual
                  ? Colores.azulOscuro
                  : Colores.textoSecundario,
            ),
          ),
        ),
      ),
    };

    final estilo = switch (estado) {
      _EstadoPaso.hecho => Tipografia.texto.copyWith(
        color: Colores.textoSecundario,
      ),
      _EstadoPaso.actual => Tipografia.texto.copyWith(
        fontWeight: FontWeight.w700,
      ),
      _EstadoPaso.pendiente => Tipografia.texto,
    };

    final fila = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          circulo,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: alTocar == null
                  ? estilo
                  : estilo.copyWith(
                      color: Colores.marca,
                      decoration: TextDecoration.underline,
                      decorationColor: Colores.marca,
                    ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: alTocar != null,
      checked: estado == _EstadoPaso.hecho,
      child: alTocar == null ? fila : InkWell(onTap: alTocar, child: fila),
    );
  }
}
