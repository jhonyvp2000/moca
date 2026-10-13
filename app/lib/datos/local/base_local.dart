import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../dominio/modelos.dart';
import 'tablas.dart';

part 'base_local.g.dart';

@DriftDatabase(
  tables: [
    Usuarios,
    Empresas,
    Membresias,
    Cuentas,
    Contrapartes,
    Comprobantes,
    ItemsComprobante,
    Categorias,
    Movimientos,
    Arqueos,
    ArqueoCuentas,
    Alertas,
    Bitacora,
    DiasCerrados,
    EventosMedicion,
    Ajustes,
  ],
)
class BaseLocal extends _$BaseLocal {
  BaseLocal([QueryExecutor? ejecutor])
    : super(ejecutor ?? driftDatabase(name: 'moca'));

  // Desde el APK de los pilotos (entrega 9) los datos de un teléfono no se
  // borran al actualizar: cada cambio de versión agrega aquí su migración.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, desde, hasta) async {},
    beforeOpen: (detalles) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // El aviso de cierre puede escribir desde segundo plano mientras la
      // app está abierta: se espera en lugar de fallar.
      await customStatement('PRAGMA busy_timeout = 5000');
    },
  );
}
