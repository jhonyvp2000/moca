import 'package:flutter/material.dart';

import '../../comun/icono_trazo.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/arqueo.dart';
import '../../dominio/equipo.dart';
import '../../dominio/moca.dart';
import '../../dominio/movimientos.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import '../moca/avisos.dart';
import 'desglose_cuentas.dart';

/// S04 · Inicio. Sin la franja de planes ni «Lo que viene» (ajustes respecto
/// al mockup), y sin la flecha para cambiar de empresa.
class PantallaInicioCompleta extends StatefulWidget {
  const PantallaInicioCompleta({
    super.key,
    required this.resumen,
    required this.alAnotarVenta,
    required this.alHacerArqueo,
    this.aviso,
    this.tarjetaAvisos,
    this.actualizado,
    this.permisos = Permisos.delDueno,
  });

  final ResumenInicio resumen;
  final VoidCallback alAnotarVenta;
  final VoidCallback alHacerArqueo;

  /// El aviso más importante, si hay alguno.
  final Aviso? aviso;

  /// El permiso de avisos, si falta pedirlo.
  final Widget? tarjetaAvisos;

  /// «Actualizado hace 5 min», si hay varias personas (entrega 18).
  final String? actualizado;

  /// Lo que el rol deja ver y hacer (entrega 20).
  final Permisos permisos;

  @override
  State<PantallaInicioCompleta> createState() => _EstadoInicioCompleta();
}

class _EstadoInicioCompleta extends State<PantallaInicioCompleta> {
  bool _ocultar = false;

  String _soles(int centimos) =>
      _ocultar ? Textos.montoOculto : formatearSoles(centimos);

  /// Filas de tres; la última se completa con huecos para que las columnas
  /// queden alineadas.
  @override
  Widget build(BuildContext context) {
    final r = widget.resumen;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.nombreNegocio,
                        style: Tipografia.tituloTarjeta.copyWith(fontSize: 17),
                      ),
                      if (widget.actualizado case final texto?)
                        Text(texto, style: Tipografia.secundario),
                    ],
                  ),
                ),
                _BotonOjo(
                  ocultando: _ocultar,
                  alTocar: () => setState(() => _ocultar = !_ocultar),
                ),
              ],
            ),
          ),
          ?widget.tarjetaAvisos,
          _conMargen(
            Tarjeta(
              relleno: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.permisos.veSaldos
                    ? [
                        Text(
                          Textos.tienesHoy,
                          style: Tipografia.textoFuerte.copyWith(
                            color: Colores.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _soles(r.tienesHoyCentimos),
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
                        const SizedBox(height: 10),
                        DesgloseDeCuentas(
                          saldos: r.saldosPorCuenta,
                          formato: _soles,
                        ),
                        if (widget.permisos.haceArqueo)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: widget.alHacerArqueo,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(
                                  0,
                                  Medidas.objetivoTactilMinimo,
                                ),
                                foregroundColor: Colores.marca,
                                textStyle: Tipografia.textoFuerte,
                              ),
                              child: const Text(Textos.hacerArqueo),
                            ),
                          ),
                        const Divider(),
                        const SizedBox(height: 12),
                        ..._semana(r),
                      ]
                    : [
                        // El ayudante ve lo que anotó hoy, no la plata del
                        // negocio (entrega 20).
                        Text(
                          Textos.hoyAnotaste,
                          style: Tipografia.textoFuerte.copyWith(
                            color: Colores.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _soles(r.ventaDeHoyCentimos),
                          style: Tipografia.cifra(
                            const TextStyle(
                              fontFamily: Tipografia.familia,
                              fontSize: 40,
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                              color: Colores.textoPrincipal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          Textos.loDemasLoVeElDueno,
                          style: Tipografia.secundario,
                        ),
                      ],
              ),
            ),
          ),
          if (widget.permisos.anota) ...[
            const SizedBox(height: Medidas.separacionTarjetas),
            _conMargen(
              FilledButton.icon(
                onPressed: widget.alAnotarVenta,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
                  ),
                ),
                icon: const IconoTrazo(
                  Icono.microfono,
                  color: Colores.sobreMarca,
                ),
                label: const Text(Textos.anotarVentaDeHoy),
              ),
            ),
            const SizedBox(height: Medidas.separacionTarjetas),
            // El aviso más importante; si no hay, la venta de hoy y el arqueo.
            _conMargen(_tarjetaMoca(r)),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaMoca(ResumenInicio r) {
    if (widget.aviso case final aviso?) {
      return TarjetaMoca(
        texto: textoAvisoEnInicio(aviso),
        accion: FilledButton(
          onPressed: () => abrirAviso(context, aviso),
          child: Text(accionAviso(aviso)),
        ),
      );
    }
    final venta = r.ventaDeHoyCentimos > 0
        ? Textos.mocaYaAnotasteHoy
        : Textos.mocaFaltaVentaDeHoy;
    // Sin arqueo para su rol, solo la venta de hoy (entrega 20).
    if (!widget.permisos.haceArqueo) return TarjetaMoca(texto: venta);
    final boton = FilledButton(
      onPressed: widget.alHacerArqueo,
      child: const Text(Textos.hacerArqueo),
    );
    return switch (r.estadoArqueo) {
      EstadoArqueo.falta => TarjetaMoca(
        texto: Textos.mocaFaltaArqueo,
        accion: boton,
      ),
      EstadoArqueo.toca => TarjetaMoca(
        texto: Textos.mocaTocaArqueo,
        accion: boton,
      ),
      EstadoArqueo.hecho => TarjetaMoca(
        texto: '$venta ${Textos.mocaArqueoHecho}',
      ),
      EstadoArqueo.nada => TarjetaMoca(texto: venta),
    };
  }

  List<Widget> _semana(ResumenInicio r) {
    if (!r.semanaConMovimientos) {
      return const [Text(Textos.semanaSinMovimientos, style: Tipografia.texto)];
    }
    final diferencia = r.diferenciaConSemanaAnteriorCentimos;
    return [
      Text.rich(
        TextSpan(
          style: Tipografia.texto,
          children: [
            const TextSpan(text: Textos.estaSemanaTeQuedo),
            TextSpan(
              text: _soles(r.semanaQuedoCentimos),
              style: Tipografia.cifra(
                const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      if (diferencia != null) ...[
        const SizedBox(height: 4),
        Row(
          children: [
            if (diferencia != 0) ...[
              IconoTrazo(
                diferencia > 0 ? Icono.entro : Icono.salio,
                color: Colores.azulOscuro,
                tamano: 16,
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                diferencia > 0
                    ? Textos.masQueLaSemanaPasada(_soles(diferencia))
                    : diferencia < 0
                    ? Textos.menosQueLaSemanaPasada(_soles(-diferencia))
                    : Textos.igualQueLaSemanaPasada,
                style: Tipografia.cifra(
                  Tipografia.secundario.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colores.azulOscuro,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 4),
      // Los montos de salida en rojo sobrio (entrega 14.9.2). Con retiros,
      // también lo que sacaste: así cuadra con la plata (entrega 14.9).
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: Textos.semanaEntro(_soles(r.semanaEntroCentimos))),
            const TextSpan(text: Textos.semanaSalio),
            TextSpan(
              text: _soles(r.semanaSalioCentimos),
              style: const TextStyle(color: Colores.salida),
            ),
            if (r.semanaAportesCentimos > 0) ...[
              const TextSpan(text: Textos.semanaPusiste),
              TextSpan(text: _soles(r.semanaAportesCentimos)),
            ],
            if (r.semanaRetirosCentimos > 0) ...[
              const TextSpan(text: Textos.semanaRetiraste),
              TextSpan(
                text: _soles(r.semanaRetirosCentimos),
                style: const TextStyle(color: Colores.salida),
              ),
            ],
          ],
        ),
        style: Tipografia.cifra(Tipografia.secundario),
      ),
    ];
  }

  Widget _conMargen(Widget hijo) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Medidas.margenLateral),
    child: hijo,
  );
}

class _BotonOjo extends StatelessWidget {
  const _BotonOjo({required this.ocultando, required this.alTocar});

  final bool ocultando;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioBoton),
      side: const BorderSide(color: Colores.bordeTarjeta),
    );
    return Tooltip(
      message: ocultando ? Textos.mostrarMontos : Textos.ocultarMontos,
      child: Material(
        color: Colores.superficie,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: alTocar,
          child: SizedBox.square(
            dimension: Medidas.objetivoTactilMinimo,
            child: Center(
              child: IconoTrazo(
                ocultando ? Icono.ojoTachado : Icono.ojo,
                color: Colores.textoPrincipal,
                tamano: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
