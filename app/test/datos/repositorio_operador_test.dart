import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moca/datos/local/base_local.dart';
import 'package:moca/datos/repositorios/repositorio_operador_local.dart';
import 'package:moca/dominio/modelos.dart';

void main() {
  late BaseLocal base;
  late RepositorioOperadorLocal repositorio;

  setUp(() {
    base = BaseLocal(NativeDatabase.memory());
    repositorio = RepositorioOperadorLocal(base);
  });

  tearDown(() => base.close());

  Future<void> llenarDatosDePrueba() async {
    final ahora = DateTime(2026, 10, 12, 21);
    await base
        .into(base.usuarios)
        .insert(UsuariosCompanion.insert(id: 'u1', creadoEn: ahora));
    await base
        .into(base.empresas)
        .insert(
          EmpresasCompanion.insert(
            id: 'e1',
            nombre: 'Bodega de prueba',
            tipoNegocio: TipoNegocio.bodega,
            modo: ModoEmpresa.simple,
            pais: 'PE',
            moneda: 'PEN',
            horaCierreMinutos: 21 * 60,
            creadoEn: ahora,
          ),
        );
    await base
        .into(base.cuentas)
        .insert(
          CuentasCompanion.insert(
            id: 'c1',
            empresaId: 'e1',
            tipo: TipoCuenta.efectivo,
            nombre: 'Efectivo',
            orden: 0,
          ),
        );
    await base
        .into(base.movimientos)
        .insert(
          MovimientosCompanion.insert(
            id: 'm1',
            empresaId: 'e1',
            tipo: TipoMovimiento.ingreso,
            cuentaId: 'c1',
            montoCentimos: 35000,
            fechaMovimiento: ahora,
            estadoPago: EstadoPago.pagado,
            montoPagadoCentimos: 35000,
            nivelConfianza: NivelConfianza.d,
            fuente: Fuente.voz,
            autorId: 'u1',
            estado: EstadoRegistro.vigente,
            estadoSincronizacion: EstadoSincronizacion.porSubir,
            creadoEn: ahora,
          ),
        );
  }

  test('Una base nueva no tiene registros', () async {
    expect(await repositorio.contarRegistros(), 0);
  });

  test('Cuenta los registros de todas las tablas', () async {
    await llenarDatosDePrueba();
    expect(await repositorio.contarRegistros(), 4);
  });

  test('Borrar todo deja la base vacía, aunque haya relaciones', () async {
    await llenarDatosDePrueba();
    await repositorio.borrarTodo();
    expect(await repositorio.contarRegistros(), 0);
  });

  test('Los montos se guardan en céntimos enteros', () async {
    await llenarDatosDePrueba();
    final m = await base.select(base.movimientos).getSingle();
    expect(m.montoCentimos, 35000);
    expect(m.estadoSincronizacion, EstadoSincronizacion.porSubir);
  });

  test('Las llaves foráneas están activas', () async {
    final fila = await base.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fila.read<int>('foreign_keys'), 1);
    expect(
      () => base
          .into(base.cuentas)
          .insert(
            CuentasCompanion.insert(
              id: 'c9',
              empresaId: 'no-existe',
              tipo: TipoCuenta.yape,
              nombre: 'Yape',
              orden: 1,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });
}
