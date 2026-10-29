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
import '../repositorios/repositorio_comprobantes_local.dart';
import '../repositorios/repositorio_movimientos_local.dart';
import '../repositorios/repositorio_primer_dia_local.dart';

/// Modo Demo (docs/prototipo-v1.md): diez semanas de una bodega que terminan
/// hoy, con la venta de hoy sin anotar. Cobra también por Plin. Se arma con los mismos repositorios
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
        await comprobantes.guardarCompra(
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
            pagado: true,
            categoriaId:
                categorias['Servicios (luz, agua, internet, teléfono)']!,
            emisorNombre: 'Electro Oriente',
            fecha: dia,
          ),
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
          'Transporte',
          TipoCuenta.efectivo,
          nota: 'Mototaxi',
          fuente: Fuente.voz,
        );
      }
      // Bolsas cada dos semanas.
      if (dia.weekday == DateTime.wednesday && hace % 14 < 7) {
        reloj = alas(16);
        await gasto(4000, 'Bolsas y envases', TipoCuenta.efectivo);
      }
      // El ayudante los sábados.
      if (dia.weekday == DateTime.saturday) {
        reloj = alas(20);
        await gasto(30000, 'Personal', TipoCuenta.efectivo, nota: 'Ayudante');
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
