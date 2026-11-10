import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../comun/enlace.dart';
import '../../comun/estructura.dart';
import '../../comun/tarjeta.dart';
import '../../dominio/cuenta_real.dart';
import '../../dominio/equipo.dart';
import '../../dominio/modelos.dart';
import '../../inyeccion.dart';
import '../../rutas.dart';
import '../../tema/colores.dart';
import '../../tema/medidas.dart';
import '../../tema/tipografia.dart';
import '../../textos/textos.dart';
import '../version/version.dart';

/// «Ajustes» (entrega 29): lo que se toca una vez, fuera de la pestaña Moca,
/// que se queda con lo del día. Cada rol ve lo mismo que antes.
class PantallaAjustes extends ConsumerWidget {
  const PantallaAjustes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permisos = ref.watch(permisosProvider).value ?? Permisos.delDueno;
    final estadoCuenta = ref.watch(situacionCuentaProvider).value?.estado;
    final guardada = estadoCuenta == EstadoCuenta.guardada;
    Widget seccion(String titulo, List<Widget> filas) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: Tipografia.tituloTarjeta),
          for (final f in filas) ...[
            const SizedBox(height: Medidas.separacionTarjetas),
            f,
          ],
        ],
      ),
    );
    final negocio = <Widget>[
      if (permisos.cambiaCuentas) ...[
        const TarjetaEnlace(
          titulo: Textos.datosDelNegocio,
          detalle: Textos.datosDelNegocioDetalle,
          ruta: Rutas.datosDelNegocio,
        ),
        const TarjetaEnlace(
          titulo: Textos.misCuentas,
          detalle: Textos.misCuentasDetalle,
          ruta: Rutas.cuentas,
        ),
      ],
      // Los pagos del negocio, con la cuenta guardada (entrega 33).
      if (guardada && permisos.rol == Rol.dueno)
        const TarjetaEnlace(
          titulo: Textos.misPagos,
          detalle: Textos.misPagosDetalle,
          ruta: Rutas.misPagos,
        ),
      if (permisos.cambiaCategorias)
        const TarjetaEnlace(
          titulo: Textos.misCategorias,
          detalle: Textos.misCategoriasDetalle,
          ruta: Rutas.categorias,
        ),
    ];
    final equipo = <Widget>[
      // Con la cuenta guardada, el equipo del negocio (entrega 19).
      if (guardada)
        const TarjetaEnlace(
          titulo: Textos.miEquipo,
          detalle: Textos.miEquipoDetalle,
          ruta: Rutas.equipo,
        ),
      // También para quien quitaron, que así acepta otra invitación
      // (entregas 22 y 22.1).
      if (guardada || estadoCuenta == EstadoCuenta.fueraDelNegocio)
        const TarjetaEnlace(
          titulo: Textos.misNegocios,
          detalle: Textos.misNegociosDetalle,
          ruta: Rutas.negocios,
        ),
    ];
    return PantallaConAcciones(
      encabezado: EncabezadoConVolver(
        titulo: Textos.ajustes,
        alVolver: () => context.pop(),
      ),
      contenido: [
        if (negocio.isNotEmpty) seccion(Textos.tuNegocio, negocio),
        if (equipo.isNotEmpty) seccion(Textos.tuEquipoAjustes, equipo),
        seccion(Textos.seguridad, [
          // Para todos los roles, en cada teléfono (entrega 16.3).
          const InterruptorHuella(),
          // Solo el titular borra (entrega 16.1); los demás salen (22.2).
          if (guardada && permisos.borraElNegocio)
            const TarjetaEnlace(
              titulo: Textos.borrarMiNegocio,
              detalle: Textos.borrarMiNegocioDetalle,
              ruta: Rutas.borrarNegocio,
            ),
          if (guardada && permisos.saleDelNegocio) const SalirDelNegocio(),
          // Una salida que siempre existe para quien no es titular (entrega
          // 37): solo este teléfono, sin tocar el negocio.
          if (guardada && permisos.saleDelNegocio) const SalirDeMocaAqui(),
          // Sin la cuenta unida, siempre hay salida desde la app (entrega
          // 45.1): entrar con el número, o empezar como recién instalada.
          if (!guardada && estadoCuenta != null) ...[
            const TarjetaEnlace(
              titulo: Textos.entrarConMiCelular,
              detalle: Textos.entrarConMiCelularDetalle,
              ruta: Rutas.cuenta,
            ),
            const BorrarEsteTelefono(),
          ],
        ]),
        // Qué versión es, para reportar un problema (entrega 26.3).
        const VersionDeMoca(),
      ],
      acciones: const [],
    );
  }
}

/// «Pedir huella al abrir Moca» (entrega 16.3). Al encenderla la pide una
/// vez, para saber que funciona en este teléfono.
class InterruptorHuella extends ConsumerStatefulWidget {
  const InterruptorHuella({super.key});

  @override
  ConsumerState<InterruptorHuella> createState() => _EstadoInterruptor();
}

class _EstadoInterruptor extends ConsumerState<InterruptorHuella> {
  bool _cambiando = false;

  Future<void> _cambiar(bool encender) async {
    setState(() => _cambiando = true);
    final mensajes = ScaffoldMessenger.of(context);
    try {
      final guardar = ref.read(guardarPedirHuellaProvider);
      if (!encender) {
        await guardar(false);
        mensajes.showSnackBar(
          const SnackBar(content: Text(Textos.huellaDesactivada)),
        );
        return;
      }
      final cerradura = ref.read(cerraduraProvider);
      if (!await cerradura.puedeUsarse()) {
        mensajes.showSnackBar(
          const SnackBar(content: Text(Textos.sinBloqueoEnElTelefono)),
        );
        return;
      }
      if (!await cerradura.verificar(Textos.confirmaQueEresTu)) return;
      await guardar(true);
      mensajes.showSnackBar(
        const SnackBar(content: Text(Textos.huellaActivada)),
      );
    } finally {
      if (mounted) setState(() => _cambiando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pide = ref.watch(pedirHuellaProvider).value ?? false;
    return Tarjeta(
      relleno: EdgeInsets.zero,
      child: Material(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          value: pide,
          onChanged: _cambiando ? null : _cambiar,
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          title: const Text(Textos.pedirHuella, style: Tipografia.textoFuerte),
          subtitle: const Text(
            Textos.pedirHuellaDetalle,
            style: Tipografia.secundario,
          ),
        ),
      ),
    );
  }
}

/// «Salir de este negocio» (entrega 22.2): pregunta antes y, al salir, la
/// pestaña dice «Ya no estás en este negocio», como si un dueño lo quitara.
class SalirDelNegocio extends ConsumerWidget {
  const SalirDelNegocio({super.key});

  Future<void> _salir(BuildContext context, WidgetRef ref) async {
    final mensajes = ScaffoldMessenger.of(context);
    final si = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text(Textos.salirDelNegocioPregunta),
        content: const Text(Textos.salirDelNegocioTexto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text(Textos.salir),
          ),
        ],
      ),
    );
    if (si != true) return;
    final resultado = await ref.read(servicioEquipoProvider).salir();
    mensajes.showSnackBar(
      SnackBar(
        content: Text(switch (resultado) {
          ResultadoEquipo.listo => Textos.salisteDelNegocio,
          ResultadoEquipo.sinSenal => Textos.necesitasSenalParaSalir,
          _ => Textos.noPudimosComprobar,
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tarjeta(
      relleno: EdgeInsets.zero,
      child: Material(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        child: InkWell(
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          onTap: () => _salir(context, ref),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Textos.salirDelNegocio,
                        style: Tipografia.textoFuerte,
                      ),
                      Text(
                        Textos.salirDelNegocioDetalle,
                        style: Tipografia.secundario,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Salir de Moca en este teléfono» (entrega 37): borra lo de Moca solo aquí.
/// Lo que falta subir sube antes; sin señal, no sale para no perderlo.
class SalirDeMocaAqui extends ConsumerWidget {
  const SalirDeMocaAqui({super.key});

  Future<void> _salir(BuildContext context, WidgetRef ref) async {
    final mensajes = ScaffoldMessenger.of(context);
    final si = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text(Textos.salirDeMocaAquiPregunta),
        content: const Text(Textos.salirDeMocaAquiTexto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text(Textos.salir),
          ),
        ],
      ),
    );
    if (si != true) return;
    final cuenta = ref.read(servicioCuentaProvider);
    if (await cuenta.hayCambiosSinSubir() && !await cuenta.subirTodo()) {
      mensajes.showSnackBar(
        const SnackBar(content: Text(Textos.salirDeMocaSinSenal)),
      );
      return;
    }
    await ref.read(repositorioOperadorProvider).borrarTodo();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tarjeta(
      relleno: EdgeInsets.zero,
      child: Material(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        child: InkWell(
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          onTap: () => _salir(context, ref),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Textos.salirDeMocaAqui, style: Tipografia.textoFuerte),
                Text(
                  Textos.salirDeMocaAquiDetalle,
                  style: Tipografia.secundario,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Borrar todo en este teléfono» (entrega 45.1): para un teléfono sin la
/// cuenta unida. Moca vuelve a la bienvenida; el servidor no se toca.
class BorrarEsteTelefono extends ConsumerWidget {
  const BorrarEsteTelefono({super.key});

  Future<void> _borrar(BuildContext context, WidgetRef ref) async {
    final si = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text(Textos.borrarEsteTelefonoPregunta),
        content: const Text(Textos.borrarEsteTelefonoTexto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text(Textos.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text(Textos.borrar),
          ),
        ],
      ),
    );
    if (si != true) return;
    await ref.read(repositorioOperadorProvider).borrarTodo();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tarjeta(
      relleno: EdgeInsets.zero,
      child: Material(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        child: InkWell(
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          onTap: () => _borrar(context, ref),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Textos.borrarEsteTelefono, style: Tipografia.textoFuerte),
                Text(
                  Textos.borrarEsteTelefonoDetalle,
                  style: Tipografia.secundario,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
