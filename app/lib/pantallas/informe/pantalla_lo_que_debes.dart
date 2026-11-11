import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/estado_vacio.dart';
import '../../comun/estructura.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/historial.dart';
import '../../inyeccion.dart';
import '../../pais/peru/formato.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import '../historial/fila_movimiento.dart';
import 'recordatorio_whatsapp.dart';
import '../../dominio/equipo.dart';
import '../../dominio/modelos.dart';

/// «Lo que debes» (entrega 38): las compras que todavía se deben, por
/// proveedor. Cada una abre su detalle, con «Ya lo pagué».
///
/// Con [teDeben], «Lo que te deben» (entrega 42): las ventas a crédito, por
/// cliente, con «Ya me pagó».
class PantallaLoQueDebes extends ConsumerStatefulWidget {
  const PantallaLoQueDebes({super.key, this.teDeben = false});

  final bool teDeben;

  @override
  ConsumerState<PantallaLoQueDebes> createState() => _EstadoLoQueDebes();
}

class _EstadoLoQueDebes extends ConsumerState<PantallaLoQueDebes> {
  late final Stream<List<FilaHistorial>> _deudas = widget.teDeben
      ? ref.read(repositorioHistorialProvider).observarLoQueTeDeben()
      : ref.read(repositorioHistorialProvider).observarLoQueDebes();

  /// A quién: el proveedor o el cliente; si no hay, la nota o la categoría.
  String _aQuien(FilaHistorial f) =>
      f.proveedor ??
      f.nota ??
      f.categoria ??
      (widget.teDeben ? Textos.sinCliente : Textos.sinProveedor);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FilaHistorial>>(
      stream: _deudas,
      builder: (context, foto) {
        final deudas = foto.data;
        final dueno =
            (ref.watch(permisosProvider).value ?? Permisos.delDueno).rol ==
            Rol.dueno;
        final grupos = <String, List<FilaHistorial>>{};
        for (final f in deudas ?? const <FilaHistorial>[]) {
          grupos.putIfAbsent(_aQuien(f), () => []).add(f);
        }
        int total(List<FilaHistorial> fs) =>
            fs.fold(0, (s, f) => s + f.montoCentimos);
        final ordenados = grupos.entries.toList()
          ..sort((a, b) => total(b.value).compareTo(total(a.value)));
        return PantallaConAcciones(
          encabezado: EncabezadoConVolver(
            titulo: widget.teDeben
                ? Textos.loQueTeDebenTitulo
                : Textos.loQueDebesTitulo,
            alVolver: () => context.pop(),
          ),
          contenido: [
            if (deudas == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (deudas.isEmpty)
              EstadoVacio(
                icono: Icons.check_circle_outline_rounded,
                titulo: widget.teDeben
                    ? Textos.nadieTeDebe
                    : Textos.noDebesNada,
              )
            else ...[
              // El total en su color: ámbar lo que te deben, coral lo que
              // debes (mejora 01).
              Container(
                padding: const EdgeInsets.all(Medidas.e5),
                decoration: BoxDecoration(
                  color: widget.teDeben
                      ? Colores.pendienteFondo
                      : Colores.egresoFondo,
                  borderRadius: BorderRadius.circular(Medidas.radioGrande),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.teDeben
                          ? Icons.call_received_rounded
                          : Icons.call_made_rounded,
                      color: widget.teDeben
                          ? Colores.pendienteTexto
                          : Colores.egreso,
                    ),
                    const SizedBox(width: Medidas.e3),
                    Expanded(
                      child: Text(
                        (widget.teDeben
                            ? Textos.teDebenTotal
                            : Textos.debesTotal)(
                          formatearSoles(total(deudas)),
                          deudas.length,
                        ),
                        style: Tipografia.cifra(
                          Tipografia.tituloFila.copyWith(
                            color: widget.teDeben
                                ? Colores.pendienteTexto
                                : Colores.egreso,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Medidas.separacionTarjetas),
              for (final MapEntry(key: aQuien, value: filas) in ordenados) ...[
                // Quién debe; la inicial va en cada fila (mejora 01).
                Text(
                  (widget.teDeben ? Textos.grupoTeDeben : Textos.grupoDeuda)(
                    aQuien,
                    formatearSoles(total(filas)),
                    filas.length,
                  ),
                  style: Tipografia.cifra(Tipografia.tituloTarjeta),
                ),
                // Recordarle por WhatsApp, solo los dueños (entrega 45).
                if (widget.teDeben && dueno)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => recordarPorWhatsApp(
                        context,
                        ref,
                        cliente: filas.first.proveedor,
                        ventas: filas,
                      ),
                      child: const Text(Textos.recordarPorWhatsApp),
                    ),
                  ),
                const SizedBox(height: Medidas.e2),
                Tarjeta(
                  relleno: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
                    child: Material(
                      color: Colores.superficie,
                      child: Column(
                        children: [
                          for (final (i, f) in filas.indexed)
                            FilaMovimiento(
                              fila: f,
                              conSeparador: i < filas.length - 1,
                              alTocar: () =>
                                  context.push(Rutas.detalleMovimiento(f.id)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (filas.any((f) => f.vence != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        for (final f in filas)
                          if (f.vence case final v?)
                            Textos.venceEl(formatearDiaYMes(v)),
                      ].join(' · '),
                      style: Tipografia.secundario,
                    ),
                  ),
                const SizedBox(height: Medidas.separacionTarjetas),
              ],
            ],
          ],
          acciones: const [],
        );
      },
    );
  }
}
