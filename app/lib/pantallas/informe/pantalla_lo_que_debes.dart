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
                // Recordarle por WhatsApp y su celular, solo los dueños
                // (entregas 45 y 53).
                if (widget.teDeben && dueno) _Cliente(filas: filas),
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

/// Lo de un cliente que solo ven los dueños: su celular, cuándo se le
/// recordó y los botones para recordarle o cambiar el número (entrega 53).
class _Cliente extends ConsumerWidget {
  const _Cliente({required this.filas});

  final List<FilaHistorial> filas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = filas.map((f) => f.contraparteId).nonNulls.firstOrNull;
    final celular = filas.map((f) => f.celular).nonNulls.firstOrNull;
    final recordado = filas
        .map((f) => f.recordadoEn)
        .nonNulls
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    final datos = [
      if (celular != null) formatearCelular(celular),
      if (recordado != null) Textos.leRecordasteEl(formatearDiaYMes(recordado)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (datos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Medidas.e1),
            child: Text(datos.join(' · '), style: Tipografia.secundario),
          ),
        Wrap(
          spacing: Medidas.e2,
          children: [
            TextButton(
              onPressed: () => recordarPorWhatsApp(
                context,
                cliente: filas.first.proveedor,
                ventas: filas,
              ),
              child: const Text(Textos.recordarPorWhatsApp),
            ),
            if (id != null)
              TextButton(
                onPressed: () => _cambiarCelular(context, ref, id, celular),
                child: Text(
                  celular == null
                      ? Textos.agregarCelular
                      : Textos.cambiarCelular,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _cambiarCelular(
    BuildContext context,
    WidgetRef ref,
    String id,
    String? actual,
  ) async {
    final repo = ref.read(repositorioHistorialProvider);
    final nuevo = await showDialog<({String? celular})>(
      context: context,
      builder: (_) => _DialogoCelular(
        cliente: filas.first.proveedor ?? Textos.sinCliente,
        actual: actual,
      ),
    );
    if (nuevo != null && nuevo.celular != actual) {
      await repo.guardarCelular(id, nuevo.celular);
    }
  }
}

/// Escribir, cambiar o borrar el celular de un cliente. Vacío lo borra.
class _DialogoCelular extends StatefulWidget {
  const _DialogoCelular({required this.cliente, required this.actual});

  final String cliente;
  final String? actual;

  @override
  State<_DialogoCelular> createState() => _EstadoDialogoCelular();
}

class _EstadoDialogoCelular extends State<_DialogoCelular> {
  late final _celular = TextEditingController(
    text: widget.actual == null ? '' : formatearCelular(widget.actual!),
  );
  bool _intento = false;

  @override
  void dispose() {
    _celular.dispose();
    super.dispose();
  }

  bool get _vacio => _celular.text.trim().isEmpty;
  String? get _valido => celularDeCliente(_celular.text);

  void _guardar() {
    if (!_vacio && _valido == null) {
      setState(() => _intento = true);
      return;
    }
    Navigator.of(context).pop((celular: _vacio ? null : _valido));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(Textos.celularDe(widget.cliente)),
      content: TextField(
        controller: _celular,
        autofocus: true,
        maxLength: 15,
        keyboardType: TextInputType.phone,
        style: Tipografia.texto,
        onChanged: (_) {
          if (_intento) setState(() {});
        },
        onSubmitted: (_) => _guardar(),
        decoration: InputDecoration(
          hintText: Textos.celularEjemplo,
          helperText: Textos.celularDelClienteAyuda,
          helperMaxLines: 2,
          errorText: _intento && !_vacio && _valido == null
              ? Textos.revisaElNumero
              : null,
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Textos.cancelar),
        ),
        FilledButton(onPressed: _guardar, child: const Text(Textos.guardar)),
      ],
    );
  }
}
