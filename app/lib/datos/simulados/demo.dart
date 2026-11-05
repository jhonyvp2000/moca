import 'dart:math';

import '../../dominio/arqueo.dart';
import '../../dominio/comprobantes.dart';
import '../../dominio/modelos.dart';
import '../../dominio/movimientos.dart';
import '../../dominio/primer_dia.dart';
import '../calculos/saldos.dart';
import '../calculos/semana.dart';
import '../local/base_local.dart';
import '../repositorios/acceso_local.dart';
import '../repositorios/repositorio_arqueo_local.dart';
import '../repositorios/repositorio_categorias_local.dart';
import '../repositorios/repositorio_comprobantes_local.dart';
import '../repositorios/repositorio_historial_local.dart';
import '../repositorios/repositorio_movimientos_local.dart';
import '../repositorios/repositorio_primer_dia_local.dart';

/// Modo Demo (docs/prototipo-v1.md): diez semanas de una bodega que terminan
/// hoy, con la venta de hoy sin anotar. Cobra también por Plin. Desde la
/// entrega 28.1 usa todas las categorías y todos los tipos de movimiento,
/// para que el informe muestre de todo. Se arma con los mismos repositorios
/// que usa la app, para que los datos cuadren igual que los reales. Siempre
/// sale igual: los «azares» tienen semilla fija.
Future<void> cargarDemo(BaseLocal base, DateTime ahora) async {
  final azar = Random(7);
  final hoy = inicioDelDia(ahora);
  final inicio = inicioDeSemana(hoy).subtract(const Duration(days: 70));
  var reloj = inicio.add(const Duration(hours: 20));
  DateTime momento() => reloj;
  int entre(int min, int max) => min + azar.nextInt(max - min + 1);

  final primerDia = RepositorioPrimerDiaLocal(base, ahora: momento);
  final movimientos = RepositorioMovimientosLocal(base, ahora: momento);
  final sinSenal = RepositorioMovimientosLocal(
    base,
    ahora: momento,
    hayConexion: () async => false,
  );
  final comprobantes = RepositorioComprobantesLocal(base, ahora: momento);
  final arqueo = RepositorioArqueoLocal(base, ahora: momento);
  final historial = RepositorioHistorialLocal(base, ahora: momento);
  final acceso = AccesoLocal(base, momento);

  await base.transaction(() async {
    await primerDia.anotarPrimeraVenta({
      TipoCuenta.efectivo: 32000,
      TipoCuenta.yape: 9000,
    });
    await primerDia.seguirSinCuenta();
    await primerDia.completarAlta(
      const DatosAlta(
        nombre: 'Bodega Don Lucho',
        tipoNegocio: TipoNegocio.bodega,
        saldos: {
          TipoCuenta.efectivo: 80000,
          TipoCuenta.yape: 30000,
          TipoCuenta.banco: 200000,
          TipoCuenta.plin: 5000,
        },
        horaCierreMinutos: 21 * 60,
        billeteras: {TipoCuenta.plin: 'Interbank Plin'},
      ),
    );
    await acceso.guardarAjuste(AccesoLocal.claveModo, AccesoLocal.modoDemo);
    final empresa = (await acceso.empresa())!;

    final categorias = {
      for (final tipo in [TipoMovimiento.ingreso, TipoMovimiento.egreso])
        for (final c in await movimientos.categorias(tipo)) c.nombre: c.id,
    };
    // Una categoría propia del dueño (entrega 31).
    categorias['Hielo'] = (await RepositorioCategoriasLocal(
      base,
      ahora: momento,
    ).agregar('Hielo', TipoMovimiento.egreso)).id!;
    Future<void> gasto(
      int centimos,
      String categoria,
      TipoCuenta cuenta, {
      String? nota,
      Fuente fuente = Fuente.texto,
    }) => movimientos.registrar(
      NuevoMovimiento(
        tipo: TipoMovimiento.egreso,
        montoCentimos: centimos,
        cuenta: cuenta,
        categoriaId: categorias[categoria],
        nota: nota,
        fuente: fuente,
      ),
    );
    Future<void> ingreso(
      int centimos,
      String categoria,
      TipoCuenta cuenta, {
      String? nota,
    }) => movimientos.registrar(
      NuevoMovimiento(
        tipo: TipoMovimiento.ingreso,
        montoCentimos: centimos,
        cuenta: cuenta,
        categoriaId: categorias[categoria],
        nota: nota,
      ),
    );
    var numero = 3100;
    Future<void> compraConQr(
      int centimos,
      TipoCuenta cuenta, {
      bool pagado = true,
    }) => comprobantes.guardarCompra(
      CompraConfirmada(
        lectura: LecturaComprobante(
          origen: OrigenLectura.qr,
          emisorIdentificacion: '20100070970',
          emisorNombre: 'Distribuidora San Martín',
          tipo: 'Factura',
          serie: 'F001',
          numero: '${numero++}',
          fechaEmision: inicioDelDia(reloj),
          totalCentimos: centimos,
        ),
        totalCentimos: centimos,
        cuenta: cuenta,
        pagado: pagado,
        categoriaId: categorias['Mercadería']!,
        emisorNombre: 'Distribuidora San Martín',
        fecha: inicioDelDia(reloj),
      ),
    );

    final diasCerrados = {
      hoy.subtract(const Duration(days: 40)),
      hoy.subtract(const Duration(days: 19)),
    };

    // La luz del día 5 (entrega 28.1): la última todavía se debe («aún no lo
    // pago»); la anterior se pagó cuatro días después con «Ya lo pagué».
    final diasDeLuz = [
      for (
        var dia = inicio.add(const Duration(days: 1));
        dia.isBefore(hoy);
        dia = DateTime(dia.year, dia.month, dia.day + 1)
      )
        if (dia.day == 5 && !diasCerrados.contains(dia)) dia,
    ];
    String? luzPorPagar;
    DateTime? diaDePagarLaLuz;

    final diasDeCompra = [
      for (
        var dia = inicio.add(const Duration(days: 1));
        dia.isBefore(hoy);
        dia = DateTime(dia.year, dia.month, dia.day + 1)
      )
        if (dia.weekday == DateTime.tuesday || dia.weekday == DateTime.friday)
          dia,
    ];

    for (
      var dia = inicio.add(const Duration(days: 1));
      dia.isBefore(hoy);
      dia = DateTime(dia.year, dia.month, dia.day + 1)
    ) {
      final hace = hoy.difference(dia).inDays;
      DateTime alas(int hora, [int minuto = 0]) =>
          DateTime(dia.year, dia.month, dia.day, hora, minuto);

      if (diasCerrados.contains(dia)) {
        await base
            .into(base.diasCerrados)
            .insert(
              DiasCerradosCompanion.insert(
                id: acceso.nuevoId(),
                empresaId: empresa.id,
                dia: dia,
              ),
            );
        continue;
      }

      // Compras de mercadería los martes y viernes, con QR.
      if (dia.weekday == DateTime.tuesday || dia.weekday == DateTime.friday) {
        reloj = alas(10);
        if (dia == diasDeCompra.last) {
          // Una compra mucho más alta de lo habitual: gasto atípico.
          await compraConQr(125000, TipoCuenta.yape);
        } else if (dia == diasDeCompra[diasDeCompra.length - 2]) {
          // La compra anterior todavía se debe.
          await compraConQr(60000, TipoCuenta.efectivo, pagado: false);
        } else {
          await compraConQr(entre(40, 70) * 1000, TipoCuenta.efectivo);
        }
      }
      // Alquiler el día 1, por banco; luz el día 5, con foto.
      if (dia.day == 1) {
        reloj = alas(9);
        await gasto(80000, 'Alquiler', TipoCuenta.banco, nota: 'Alquiler');
      }
      if (dia.day == 5) {
        reloj = alas(11);
        final ultima = diasDeLuz.isNotEmpty && dia == diasDeLuz.last;
        final anterior =
            diasDeLuz.length >= 2 && dia == diasDeLuz[diasDeLuz.length - 2];
        final luz = await comprobantes.guardarCompra(
          CompraConfirmada(
            lectura: LecturaComprobante(
              origen: OrigenLectura.foto,
              emisorNombre: 'Electro Oriente',
              tipo: 'Recibo',
              fechaEmision: dia,
              totalCentimos: 14230,
            ),
            totalCentimos: 14230,
            cuenta: TipoCuenta.banco,
            pagado: !ultima && !anterior,
            categoriaId:
                categorias['Servicios (luz, agua, internet, teléfono)']!,
            emisorNombre: 'Electro Oriente',
            fecha: dia,
          ),
        );
        if (anterior) {
          luzPorPagar = luz.ids.first;
          diaDePagarLaLuz = DateTime(dia.year, dia.month, dia.day + 4);
        }
      }
      // Si ese día cerró, la paga el siguiente.
      if (luzPorPagar case final id?
          when diaDePagarLaLuz != null && !dia.isBefore(diaDePagarLaLuz)) {
        reloj = alas(12);
        await historial.pagar(id, cuenta: TipoCuenta.banco, dia: dia);
        luzPorPagar = null;
      }
      // Lo de cada mes (entrega 28.1): el contador, el internet, la cuota
      // del préstamo (desde que lo pidió) y la venta de cajas vacías.
      if (dia.day == 10) {
        reloj = alas(10, 30);
        await gasto(15000, 'Contador o gestoría', TipoCuenta.banco);
      }
      if (dia.day == 15) {
        reloj = alas(10, 30);
        await gasto(
          8900,
          'Servicios (luz, agua, internet, teléfono)',
          TipoCuenta.yape,
          nota: 'Internet',
        );
      }
      if (dia.day == 20 && hace < 63) {
        reloj = alas(10, 30);
        await gasto(
          45000,
          'Cuota de préstamo',
          TipoCuenta.banco,
          nota: 'Caja Piura',
        );
      }
      if (dia.day == 25) {
        reloj = alas(17);
        await ingreso(
          4000,
          'Otro ingreso',
          TipoCuenta.efectivo,
          nota: 'Venta de cajas vacías',
        );
      }
      // Una sola vez: el préstamo, la licencia, los volantes y un gasto
      // suelto; y la congeladora alquilada para una fiesta.
      if (hace == 63) {
        reloj = alas(9, 30);
        await movimientos.registrar(
          const NuevoMovimiento(
            tipo: TipoMovimiento.aporte,
            montoCentimos: 300000,
            cuenta: TipoCuenta.banco,
            nota: 'Préstamo de Caja Piura',
          ),
        );
      }
      if (hace == 45) {
        reloj = alas(11, 30);
        await gasto(
          12000,
          'Impuestos y trámites',
          TipoCuenta.banco,
          nota: 'Licencia municipal',
        );
      }
      if (hace == 30) {
        reloj = alas(11, 30);
        await gasto(6000, 'Publicidad', TipoCuenta.efectivo, nota: 'Volantes');
      }
      if (hace == 25) {
        reloj = alas(12, 30);
        await gasto(3500, 'Otros', TipoCuenta.efectivo, nota: 'Candado');
      }
      if (hace == 17) {
        reloj = alas(13);
        await ingreso(
          25000,
          'Ingreso ocasional',
          TipoCuenta.yape,
          nota: 'Alquiler de la congeladora',
        );
      }
      // Una foto que hubo que completar a mano (nivel C).
      if (hace == 9) {
        reloj = alas(12);
        await comprobantes.guardarCompra(
          CompraConfirmada(
            lectura: LecturaComprobante(
              origen: OrigenLectura.foto,
              legible: false,
              fechaEmision: dia,
              totalCentimos: 8650,
            ),
            totalCentimos: 8650,
            cuenta: TipoCuenta.efectivo,
            pagado: true,
            categoriaId: categorias['Mantenimiento y reparaciones']!,
            emisorNombre: 'Ferretería El Constructor',
            fecha: dia,
          ),
        );
      }
      // Mototaxi dos veces por semana, dicho por voz.
      if (dia.weekday == DateTime.monday || dia.weekday == DateTime.thursday) {
        reloj = alas(15);
        await gasto(
          entre(10, 20) * 100,
          'Movilidad del negocio',
          TipoCuenta.efectivo,
          nota: 'Mototaxi',
          fuente: Fuente.voz,
        );
      }
      // Lo que pagan los que le deben, los lunes y jueves por la tarde.
      if (dia.weekday == DateTime.monday || dia.weekday == DateTime.thursday) {
        reloj = alas(18);
        await ingreso(
          entre(2, 6) * 1000,
          'Cobro de fiado',
          hace.isEven ? TipoCuenta.yape : TipoCuenta.efectivo,
          nota: 'Doña Rosa',
        );
      }
      // Combustible de la moto los miércoles; flete con la compra del
      // viernes, cada dos semanas.
      if (dia.weekday == DateTime.wednesday) {
        reloj = alas(9);
        await gasto(
          entre(30, 50) * 100,
          'Combustible',
          TipoCuenta.efectivo,
          nota: 'Moto',
          fuente: Fuente.voz,
        );
      }
      if (dia.weekday == DateTime.friday && hace % 14 < 7) {
        reloj = alas(10, 30);
        await gasto(2500, 'Flete', TipoCuenta.efectivo);
      }
      // Bolsas cada dos semanas.
      if (dia.weekday == DateTime.wednesday && hace % 14 < 7) {
        reloj = alas(16);
        await gasto(4000, 'Bolsas y envases', TipoCuenta.efectivo);
      }
      // Hielo para las bebidas los sábados, en su categoría propia. Monto
      // fijo, para no mover los números al azar del resto de la Demo.
      if (dia.weekday == DateTime.saturday) {
        reloj = alas(8, 30);
        await gasto(600, 'Hielo', TipoCuenta.efectivo);
      }
      // El ayudante los sábados.
      if (dia.weekday == DateTime.saturday) {
        reloj = alas(20);
        await gasto(
          30000,
          'Sueldos del personal',
          TipoCuenta.efectivo,
          nota: 'Ayudante',
        );
      }

      // La venta del día a la hora de cierre; más el fin de semana.
      reloj = alas(21);
      final fin = dia.weekday >= DateTime.friday;
      final venta = {
        TipoCuenta.efectivo: (fin ? entre(38, 52) : entre(25, 40)) * 1000,
        TipoCuenta.yape: (fin ? entre(15, 22) : entre(8, 16)) * 1000,
        TipoCuenta.plin: (fin ? entre(4, 8) : entre(2, 5)) * 1000,
        if (dia.weekday == DateTime.saturday) TipoCuenta.banco: 25000,
      };
      // Las dos últimas, guardadas sin señal: quedan «por subir».
      await (hace <= 2 ? sinSenal : movimientos).anotarVentaDelDia(
        venta,
        fuente: hace.isEven ? Fuente.voz : Fuente.texto,
      );

      // Hace tres semanas el dueño puso plata de su bolsillo para comprar
      // mercadería (entrega 14.11). Sin azar, para no cambiar lo demás.
      if (hace == 20) {
        reloj = alas(8, 30);
        await movimientos.registrar(
          const NuevoMovimiento(
            tipo: TipoMovimiento.aporte,
            montoCentimos: 50000,
            cuenta: TipoCuenta.efectivo,
            nota: 'Para la mercadería de fin de mes',
          ),
        );
      }

      // Hace dos semanas depositó en el BCP lo que sobraba en la caja
      // (entrega 21.1): no es venta ni gasto. Sin azar, como el aporte.
      if (hace == 13) {
        reloj = alas(10);
        await movimientos.registrar(
          const NuevoMovimiento(
            tipo: TipoMovimiento.transferencia,
            montoCentimos: 30000,
            cuenta: TipoCuenta.efectivo,
            cuentaDestino: TipoCuenta.banco,
            nota: 'Depósito al BCP',
          ),
        );
      }

      // La semana pasada pasó lo de Yape al BCP.
      if (hace == 6) {
        reloj = alas(10, 30);
        await movimientos.registrar(
          const NuevoMovimiento(
            tipo: TipoMovimiento.transferencia,
            montoCentimos: 20000,
            cuenta: TipoCuenta.yape,
            cuentaDestino: TipoCuenta.banco,
            nota: 'De Yape al BCP',
          ),
        );
      }

      // El domingo: retiro para el dueño y arqueo.
      if (dia.weekday == DateTime.sunday) {
        reloj = alas(21, 20);
        await movimientos.registrar(
          NuevoMovimiento(
            tipo: TipoMovimiento.retiro,
            montoCentimos: entre(60, 90) * 1000,
            cuenta: TipoCuenta.efectivo,
          ),
        );
        reloj = alas(21, 40);
        final semana = hace ~/ 7;
        final cuentas = await arqueo.preparar();
        await arqueo.guardar([
          for (final c in cuentas)
            switch ((c.cuenta, semana)) {
              // Hace dos semanas: faltaron S/ 30 sin explicar.
              (TipoCuenta.efectivo, 1) => ConteoCuenta(
                cuenta: c.cuenta,
                contadoCentimos: c.calculadoCentimos - 3000,
                motivo: MotivoArqueo.noLoSe,
              ),
              (TipoCuenta.efectivo, 4) => ConteoCuenta(
                cuenta: c.cuenta,
                contadoCentimos: c.calculadoCentimos - 5000,
                motivo: MotivoArqueo.retiroParaMi,
              ),
              // Un gasto que olvidó anotar y una venta que no anotó
              // (entrega 28.1).
              (TipoCuenta.efectivo, 2) => ConteoCuenta(
                cuenta: c.cuenta,
                contadoCentimos: c.calculadoCentimos - 2500,
                motivo: MotivoArqueo.gastoOlvidado,
                categoriaId: categorias['Bolsas y envases'],
              ),
              (TipoCuenta.efectivo, 3) => ConteoCuenta(
                cuenta: c.cuenta,
                contadoCentimos: c.calculadoCentimos + 1500,
                motivo: MotivoArqueo.ventaNoAnotada,
              ),
              (TipoCuenta.yape, 6) => ConteoCuenta(
                cuenta: c.cuenta,
                contadoCentimos: c.calculadoCentimos + 2000,
                motivo: MotivoArqueo.errorDeVuelto,
              ),
              _ => ConteoCuenta(
                cuenta: c.cuenta,
                contadoCentimos: c.calculadoCentimos,
              ),
            },
        ]);
      }
    }
  });
}
