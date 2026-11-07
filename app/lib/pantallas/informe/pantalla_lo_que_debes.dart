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

/// «Lo que debes» (entrega 38): las compras que todavía se deben, por
/// proveedor. Cada una abre su detalle, con «Ya lo pagué».
class PantallaLoQueDebes extends ConsumerStatefulWidget {
  const PantallaLoQueDebes({super.key});

  @override
  ConsumerState<PantallaLoQueDebes> createState() => _EstadoLoQueDebes();
}

class _EstadoLoQueDebes extends ConsumerState<PantallaLoQueDebes> {
  late final Stream<List<FilaHistorial>> _deudas = ref
      .read(repositorioHistorialProvider)
      .observarLoQueDebes();

  /// A quién: el proveedor; si no hay, la nota o la categoría.
  static String _aQuien(FilaHistorial f) =>
      f.proveedor ?? f.nota ?? f.categoria ?? Textos.sinProveedor;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FilaHistorial>>(
      stream: _deudas,
      builder: (context, foto) {
        final deudas = foto.data;
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
            titulo: Textos.loQueDebesTitulo,
            alVolver: () => context.pop(),
          ),
          contenido: [
            if (deudas == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (deudas.isEmpty)
              const Text(Textos.noDebesNada, style: Tipografia.texto)
            else ...[
              Text(
                Textos.debesTotal(formatearSoles(total(deudas)), deudas.length),
                style: Tipografia.tituloTarjeta,
              ),
              const SizedBox(height: Medidas.separacionTarjetas),
              for (final MapEntry(key: aQuien, value: filas) in ordenados) ...[
                Text(
                  Textos.grupoDeuda(
                    aQuien,
                    formatearSoles(total(filas)),
                    filas.length,
                  ),
                  style: Tipografia.textoFuerte,
                ),
                const SizedBox(height: 6),
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
