import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../comun/icono_trazo.dart';
import '../comun/tarjeta.dart';
import '../dominio/cuenta_real.dart';
import '../dominio/voz.dart';
import '../dominio/modelos.dart';
import '../inyeccion.dart';
import '../pais/peru/formato.dart';
import '../rutas.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../tema/tipografia.dart';
import '../textos/textos.dart';

final conteoRegistrosProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(repositorioOperadorProvider).contarRegistros(),
);

/// Ajuste oculto para quien organiza la prueba. Se abre manteniendo
/// presionado 3 segundos el isotipo de la pestaña Moca.
class PantallaOperador extends ConsumerWidget {
  const PantallaOperador({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conteo = ref.watch(conteoRegistrosProvider);
    final sinSenal = ref.watch(simularSinSenalProvider);
    final videosSinEnlace = ref.watch(videosSinEnlaceProvider);
    final diasAdelantados = ref.watch(adelantoDelRelojProvider);
    // Solo con la cuenta guardada hay algo que borrar en el servidor.
    final cuenta = ref.watch(situacionCuentaProvider).value;
    final conCuenta = cuenta?.estado == EstadoCuenta.guardada;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const IconoTrazo(
            Icono.volver,
            color: Colores.textoPrincipal,
            tamano: 24,
          ),
        ),
        title: const Text(Textos.tituloOperador),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Medidas.margenLateral,
          0,
          Medidas.margenLateral,
          24,
        ),
        children: [
          const Text(Textos.subtituloOperador, style: Tipografia.secundario),
          const SizedBox(height: 16),
          Tarjeta(
            // Mientras se vuelve a contar, se mantiene la cifra anterior.
            child: Text(switch (conteo.value) {
              final int registros => Textos.registrosGuardados(registros),
              null => Textos.contandoRegistros,
            }, style: Tipografia.texto),
          ),
          const SizedBox(height: Medidas.separacionTarjetas),
          Tarjeta(
            relleno: EdgeInsets.zero,
            child: Column(
              children: [
                _Opcion(
                  titulo: Textos.borrarTodo,
                  detalle: Textos.borrarTodoDetalle,
                  alTocar: () => _borrarTodo(context, ref),
                ),
                if (conCuenta) ...[
                  const Divider(),
                  _Opcion(
                    titulo: Textos.borrarEnServidor,
                    detalle: Textos.borrarEnServidorDetalle,
                    alTocar: () =>
                        _borrarEnServidor(context, ref, cuenta?.celular),
                  ),
                ],
                const Divider(),
                _Opcion(
                  titulo: Textos.empezarPrimerDia,
                  detalle: Textos.empezarPrimerDiaDetalle,
                  alTocar: () => _empezarPrimerDia(context, ref),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.saltarPrimeraSemana,
                  detalle: Textos.saltarPrimeraSemanaDetalle,
                  alTocar: () => _saltarPrimeraSemana(context, ref),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.pedirArqueo,
                  detalle: Textos.pedirArqueoDetalle,
                  alTocar: () async {
                    final mensajes = ScaffoldMessenger.of(context);
                    await ref.read(repositorioOperadorProvider).pedirArqueo();
                    mensajes.showSnackBar(
                      const SnackBar(content: Text(Textos.arqueoPedido)),
                    );
                  },
                ),
                // Simular otra persona con un solo teléfono (entrega 20.1).
                const Divider(),
                _Opcion(
                  titulo: Textos.verComoRol,
                  detalle: Textos.verComoRolDetalle,
                  alTocar: () => _verComo(context, ref),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.simularVentaDeOtro,
                  detalle: Textos.simularVentaDeOtroDetalle,
                  alTocar: () async {
                    final mensajes = ScaffoldMessenger.of(context);
                    await ref
                        .read(repositorioOperadorProvider)
                        .simularVentaDeOtro();
                    mensajes.showSnackBar(
                      const SnackBar(content: Text(Textos.ventaDeOtroSimulada)),
                    );
                  },
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.salirDeLaSimulacion,
                  detalle: Textos.salirDeLaSimulacionDetalle,
                  alTocar: () async {
                    final mensajes = ScaffoldMessenger.of(context);
                    await ref
                        .read(repositorioOperadorProvider)
                        .salirDeLaSimulacion();
                    mensajes.showSnackBar(
                      const SnackBar(content: Text(Textos.simulacionTerminada)),
                    );
                  },
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.empezarDemo,
                  detalle: Textos.empezarDemoDetalle,
                  alTocar: () => _empezarDemo(context, ref),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.forzarFotoIlegible,
                  detalle: Textos.forzarFotoIlegibleDetalle,
                  alTocar: () {
                    ref.read(forzarIlegibleProvider.notifier).forzar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(Textos.fotoIlegibleForzada)),
                    );
                  },
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.elegirFrase,
                  detalle: Textos.elegirFraseDetalle,
                  alTocar: () => _elegirFrase(context, ref),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.adelantarReloj,
                  detalle: Textos.adelantarRelojDetalle,
                  alTocar: () {
                    ref
                        .read(adelantoDelRelojProvider.notifier)
                        .adelantarUnDia();
                    final hoy = ref.read(relojProvider)();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            Textos.relojAdelantado(formatearFechaLarga(hoy)),
                          ),
                        ),
                      );
                  },
                ),
                if (diasAdelantados > 0) ...[
                  const Divider(),
                  _Opcion(
                    titulo: Textos.volverHoraReal,
                    detalle: Textos.volverHoraRealDetalle(diasAdelantados),
                    alTocar: () {
                      ref
                          .read(adelantoDelRelojProvider.notifier)
                          .volverALaHoraReal();
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text(Textos.horaReal)),
                        );
                    },
                  ),
                ],
                const Divider(),
                _Opcion(
                  titulo: Textos.probarAvisoCierre,
                  detalle: Textos.probarAvisoCierreDetalle,
                  alTocar: () async {
                    final mensajes = ScaffoldMessenger.of(context);
                    await ref.read(notificadorProvider).probarAvisoCierre();
                    mensajes.showSnackBar(
                      const SnackBar(
                        content: Text(Textos.avisoDePruebaEnviado),
                      ),
                    );
                  },
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.verAvisosProgramados,
                  detalle: Textos.verAvisosProgramadosDetalle,
                  alTocar: () => _verAvisosProgramados(context, ref),
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.simularSinSenal,
                  detalle: sinSenal
                      ? Textos.simularSinSenalActivo
                      : Textos.simularSinSenalDetalle,
                  alTocar: () {
                    ref.read(simularSinSenalProvider.notifier).cambiar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          sinSenal
                              ? Textos.senalDelTelefono
                              : Textos.sinSenalSimulada,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.videosSinEnlace,
                  detalle: Textos.videosSinEnlaceDetalle,
                  alTocar: () {
                    ref.read(videosSinEnlaceProvider.notifier).cambiar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          videosSinEnlace
                              ? Textos.videosSinEnlaceDesactivado
                              : Textos.videosSinEnlaceActivado,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                _Opcion(
                  titulo: Textos.exportarMedicion,
                  detalle: Textos.exportarMedicionDetalle,
                  alTocar: () => _exportarMedicion(ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verComo(BuildContext context, WidgetRef ref) async {
    final elegido = await showModalBottomSheet<Rol>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            for (final rol in Rol.values)
              ListTile(
                minTileHeight: Medidas.objetivoTactilMinimo + 12,
                title: Text(
                  Textos.nombreRol(rol),
                  style: Tipografia.textoFuerte,
                ),
                subtitle: Text(
                  Textos.detalleRol(rol),
                  style: Tipografia.secundario,
                ),
                onTap: () => Navigator.of(context).pop(rol),
              ),
          ],
        ),
      ),
    );
    if (elegido == null) return;
    await ref
        .read(repositorioOperadorProvider)
        .verComo(elegido == Rol.dueno ? null : elegido);
    if (context.mounted) context.go(Rutas.inicio);
  }

  Future<void> _elegirFrase(BuildContext context, WidgetRef ref) async {
    final frases = ref.read(frasesDeEjemploProvider);
    final mensajes = ScaffoldMessenger.of(context);
    final elegida = await showModalBottomSheet<FraseEjemplo>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Medidas.margenLateral,
                0,
                Medidas.margenLateral,
                8,
              ),
              child: Text(Textos.elegirFrase, style: Tipografia.tituloPantalla),
            ),
            for (final frase in frases)
              ListTile(
                minTileHeight: Medidas.objetivoTactilMinimo + 12,
                title: Text('«${frase.texto}»', style: Tipografia.texto),
                onTap: () => Navigator.of(context).pop(frase),
              ),
          ],
        ),
      ),
    );
    if (elegida == null) return;
    ref.read(fraseElegidaProvider.notifier).elegir(elegida);
    mensajes.showSnackBar(
      SnackBar(content: Text(Textos.fraseElegida(elegida.texto))),
    );
  }

  Future<void> _verAvisosProgramados(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final guardados = await ref.read(notificadorProvider).guardados();
    final plan = {
      for (final n in await ref.read(repositorioAvisoCierreProvider).plan())
        n.id: n,
    };
    final lineas = [
      if (guardados.alAbrir case final n?) Textos.guardadosAlAbrir(n),
      if (guardados.ahora.isEmpty) Textos.sinAvisosGuardados,
      for (final id in guardados.ahora..sort())
        switch (plan[id]) {
          final n? =>
            '${Textos.nombreNotificacion(n.tipo)} · '
                '${formatearFechaLarga(n.cuando)} · '
                '${formatearHora(n.cuando.hour * 60 + n.cuando.minute)}',
          null => Textos.otroAviso,
        },
    ];
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Textos.verAvisosProgramados),
        content: SingleChildScrollView(
          child: Text(lineas.join('\n\n'), style: Tipografia.texto),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(Textos.entendido),
          ),
        ],
      ),
    );
  }

  Future<void> _empezarDemo(BuildContext context, WidgetRef ref) async {
    final confirmado = await _confirmar(
      context,
      titulo: Textos.confirmarDemoTitulo,
      boton: Textos.empezarDemoBoton,
    );
    if (!confirmado) return;
    await ref.read(repositorioOperadorProvider).cargarDemo();
    ref.invalidate(conteoRegistrosProvider);
    if (context.mounted) context.go(Rutas.inicio);
  }

  Future<void> _exportarMedicion(WidgetRef ref) async {
    final csv = await ref.read(medicionProvider).exportarCsv();
    final carpeta = await getTemporaryDirectory();
    final hoy = ref.read(relojProvider)();
    final archivo = File(
      '${carpeta.path}/moca-medicion-'
      '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-'
      '${hoy.day.toString().padLeft(2, '0')}.csv',
    );
    await archivo.writeAsString(csv, flush: true);
    await ref
        .read(compartidorProvider)
        .compartirArchivo(
          archivo.path,
          asunto: Textos.medicionDeMoca,
          tipo: 'text/csv',
        );
  }

  Future<void> _saltarPrimeraSemana(BuildContext context, WidgetRef ref) async {
    final mensajes = ScaffoldMessenger.of(context);
    await ref.read(repositorioOperadorProvider).saltarPrimeraSemana();
    mensajes.showSnackBar(
      const SnackBar(content: Text(Textos.primeraSemanaSaltada)),
    );
  }

  Future<void> _empezarPrimerDia(BuildContext context, WidgetRef ref) async {
    final confirmado = await _confirmar(
      context,
      titulo: Textos.confirmarPrimerDiaTitulo,
      boton: Textos.empezarPrimerDiaBoton,
    );
    if (!confirmado) return;
    await ref.read(repositorioOperadorProvider).borrarTodo();
    if (context.mounted) context.go(Rutas.bienvenida);
  }

  Future<bool> _confirmar(
    BuildContext context, {
    required String titulo,
    required String boton,
  }) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: const Text(Textos.confirmarBorrarTexto),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(boton),
          ),
        ],
      ),
    );
    return confirmado == true;
  }

  Future<void> _borrarTodo(BuildContext context, WidgetRef ref) async {
    final confirmado = await _confirmar(
      context,
      titulo: Textos.confirmarBorrarTitulo,
      boton: Textos.borrarTodoBoton,
    );
    if (!confirmado || !context.mounted) return;

    final mensajes = ScaffoldMessenger.of(context);
    await ref.read(repositorioOperadorProvider).borrarTodo();
    ref.invalidate(conteoRegistrosProvider);
    // Sin datos no hay negocio: la app vuelve a la Bienvenida.
    if (context.mounted) context.go(Rutas.bienvenida);
    mensajes.showSnackBar(const SnackBar(content: Text(Textos.seBorroTodo)));
  }

  /// Dos pasos: el aviso y escribir BORRAR. Primero el servidor; el
  /// teléfono se borra solo si el servidor ya borró (entrega 14.8).
  Future<void> _borrarEnServidor(
    BuildContext context,
    WidgetRef ref,
    String? celular,
  ) async {
    final seguir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Textos.borrarEnServidorTitulo),
        content: Text(
          Textos.borrarEnServidorAviso(
            celular == null ? '' : formatearCelular(celular),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Textos.continuar),
          ),
        ],
      ),
    );
    if (seguir != true || !context.mounted) return;
    final resultado = await showDialog<ResultadoBorrado>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DialogoBorrarParaSiempre(),
    );
    if (resultado == null || !context.mounted) return;
    final mensajes = ScaffoldMessenger.of(context);
    if (resultado != ResultadoBorrado.listo) {
      mensajes.showSnackBar(
        SnackBar(
          content: Text(
            resultado == ResultadoBorrado.sinSenal
                ? Textos.borrarSinSenal
                : Textos.borrarFallo,
          ),
        ),
      );
      return;
    }
    await ref.read(repositorioOperadorProvider).borrarTodo();
    ref.invalidate(conteoRegistrosProvider);
    if (context.mounted) context.go(Rutas.bienvenida);
    mensajes.showSnackBar(
      const SnackBar(content: Text(Textos.seBorroTodoEnServidor)),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({required this.titulo, required this.detalle, this.alTocar});

  final String titulo;
  final String detalle;

  /// Nulo mientras la opción no está disponible.
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final activa = alTocar != null;
    return InkWell(
      onTap: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Tipografia.textoFuerte.copyWith(
                        color: activa
                            ? Colores.textoPrincipal
                            : Colores.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(detalle, style: Tipografia.secundario),
                  ],
                ),
              ),
              if (activa) const IconoTrazo(Icono.borrar, color: Colores.marca),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hay que escribir BORRAR para que se active el botón. Borra en el
/// servidor y devuelve cómo salió.
class _DialogoBorrarParaSiempre extends ConsumerStatefulWidget {
  const _DialogoBorrarParaSiempre();

  @override
  ConsumerState<_DialogoBorrarParaSiempre> createState() =>
      _EstadoDialogoBorrar();
}

class _EstadoDialogoBorrar extends ConsumerState<_DialogoBorrarParaSiempre> {
  final _texto = TextEditingController();
  bool _borrando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  bool get _escrito => _texto.text.trim().toUpperCase() == 'BORRAR';

  Future<void> _borrar() async {
    setState(() => _borrando = true);
    final resultado = await ref
        .read(servicioCuentaProvider)
        .borrarEnElServidor();
    if (mounted) Navigator.of(context).pop(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Textos.borrarEnServidorTitulo),
      content: TextField(
        controller: _texto,
        enabled: !_borrando,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(labelText: Textos.escribeBorrar),
      ),
      actions: [
        TextButton(
          onPressed: _borrando ? null : () => Navigator.of(context).pop(),
          child: const Text(Textos.cancelar),
        ),
        TextButton(
          onPressed: _escrito && !_borrando ? _borrar : null,
          child: Text(_borrando ? Textos.borrando : Textos.borrarParaSiempre),
        ),
      ],
    );
  }
}
