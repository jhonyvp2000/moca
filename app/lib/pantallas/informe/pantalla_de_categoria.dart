import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Los registros de una categoría del informe en el mes (entrega 38): suman
/// lo de su barra. Cada uno abre su detalle.
class PantallaDeCategoria extends ConsumerStatefulWidget {
  const PantallaDeCategoria({super.key, required this.consulta});

  final ConsultaDeCategoria consulta;

  @override
  ConsumerState<PantallaDeCategoria> createState() => _EstadoDeCategoria();
}

class _EstadoDeCategoria extends ConsumerState<PantallaDeCategoria> {
  late final Stream<List<FilaHistorial>> _filas = ref
      .read(repositorioHistorialProvider)
      .observarDeCategoria(widget.consulta);

  @override
  Widget build(BuildContext context) {
    final c = widget.consulta;
    final ahora = ref.read(relojProvider)();
    final periodo = Textos.periodoDelMes(
      c.mes,
      enCurso: c.mes == DateTime(ahora.year, ahora.month),
      hoy: ahora,
    );
    return StreamBuilder<List<FilaHistorial>>(
      stream: _filas,
      builder: (context, foto) {
        final filas = foto.data;
        return PantallaConAcciones(
          encabezado: EncabezadoConVolver(
            titulo: c.titulo,
            alVolver: () => context.pop(),
          ),
          contenido: [
            Text(periodo, style: Tipografia.secundario),
            const SizedBox(height: 8),
            if (filas == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Text(
                Textos.totalDeRegistros(
                  formatearSoles(filas.fold(0, (s, f) => s + f.montoCentimos)),
                  filas.length,
                ),
                style: Tipografia.tituloTarjeta,
              ),
              const SizedBox(height: Medidas.separacionTarjetas),
              if (filas.isNotEmpty)
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
            ],
          ],
          acciones: const [],
        );
      },
    );
  }
}
