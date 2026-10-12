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

  // Mientras se construye el prototipo, un cambio de versión borra y recrea
  // las tablas: solo hay datos de prueba. Antes de entregar el APK a los
  // pilotos, esta estrategia pasa a migrar sin perder datos.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, desde, hasta) async {
      for (final tabla in allTables.toList().reversed) {
        await m.deleteTable(tabla.actualTableName);
      }
      await m.createAll();
    },
    beforeOpen: (detalles) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
