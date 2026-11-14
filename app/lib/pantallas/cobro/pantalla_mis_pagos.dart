import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estructura.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/cobro.dart';
import '../../dominio/google_play.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';

/// «Mis pagos de Moca» (entrega 33), solo para dueños: hasta cuándo está
/// pagada y cada pago, con lo que cubrió y cómo se pagó.
class PantallaMisPagos extends ConsumerStatefulWidget {
  const PantallaMisPagos({super.key});

  @override
  ConsumerState<PantallaMisPagos> createState() => _EstadoMisPagos();
}

class _EstadoMisPagos extends ConsumerState<PantallaMisPagos> {
  ({MisPagos? pagos, bool alDia})? _leido;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final leido = await ref.read(servicioCobroProvider).misPagos();
    if (mounted) setState(() => _leido = leido);
  }

  @override
  Widget build(BuildContext context) {
    final cobro = ref.watch(cobroProvider).value ?? Cobro.sinCobro;
    final leido = _leido;
    final misPagos = leido?.pagos;
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.misPagos,
        alVolver: () => context.pop(),
      ),
      contenido: [
        Tarjeta(
          child: Text(
            Textos.resumenDeMisPagos(cobro),
            style: Tipografia.textoFuerte,
          ),
        ),
        // Con Google Play, se cambia o cancela allá (entrega 80).
        if (cobro.googleVigente || cobro.googleProblema) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => ref
                  .read(abridorProvider)
                  .abrir(administrarEnGooglePlay(null)),
              child: const Text(Textos.administrarEnGooglePlay),
            ),
          ),
        ],
        const SizedBox(height: Medidas.separacionTarjetas),
        if (leido == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (misPagos == null)
          const Aviso(texto: Textos.misPagosSinSenal)
        else ...[
          if (!leido.alDia) ...[
            Text(
              Textos.actualizadoEl(formatearDiaYMes(misPagos.actualizado)),
              style: Tipografia.secundario,
            ),
            const SizedBox(height: 8),
          ],
          if (misPagos.enRevision > 0) ...[
            const Aviso(texto: Textos.pagoEnRevision),
            const SizedBox(height: 8),
          ],
          if (misPagos.pagos.isEmpty)
            const Text(Textos.sinPagosTodavia, style: Tipografia.secundario)
          else
            Tarjeta(
              relleno: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, p) in misPagos.pagos.indexed)
                    _FilaPago(
                      pago: p,
                      conSeparador: i < misPagos.pagos.length - 1,
                    ),
                ],
              ),
            ),
        ],
      ],
      acciones: const [],
    );
  }
}

class _FilaPago extends StatelessWidget {
  const _FilaPago({required this.pago, required this.conSeparador});

  final PagoDeMoca pago;
  final bool conSeparador;

  @override
  Widget build(BuildContext context) {
    final p = pago;
    final apagado = p.anulado ? Colores.textoSecundario : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: conSeparador
            ? const Border(bottom: BorderSide(color: Colores.bordeTarjeta))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatearDiaYMes(p.pagadoEn),
                  style: Tipografia.textoFuerte.copyWith(color: apagado),
                ),
              ),
              Text(
                formatearSolesComprobante(p.montoCentimos),
                style: Tipografia.textoFuerte.copyWith(color: apagado),
              ),
            ],
          ),
          Text(
            Textos.planDelPago(p.plan, p.personasExtra),
            style: Tipografia.secundario,
          ),
          Text(
            Textos.cubrio(formatearDiaYMes(p.desde), formatearDiaYMes(p.hasta)),
            style: Tipografia.secundario,
          ),
          Text(switch (p.medio) {
            MedioDePago.mercadoPago => Textos.porMercadoPago(p.operacion),
            MedioDePago.googlePlay => Textos.porGooglePlay,
            MedioDePago.yape => Textos.porYape,
          }, style: Tipografia.secundario),
          if (p.anulado)
            const Text(
              Textos.pagoDevueltoNoCuenta,
              style: Tipografia.secundario,
            ),
        ],
      ),
    );
  }
}
