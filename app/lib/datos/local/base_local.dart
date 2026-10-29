import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../dominio/modelos.dart';
import 'categorias_al_dia.dart';
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
    Subidas,
  ],
)
class BaseLocal extends _$BaseLocal {
  BaseLocal([QueryExecutor? ejecutor])
    : super(ejecutor ?? driftDatabase(name: 'moca'));

  // Desde el APK de los pilotos (entrega 9) los datos de un teléfono no se
  // borran al actualizar: cada cambio de versión agrega aquí su migración.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, desde, hasta) async {
      // Entrega 18: lo que ya está en el servidor, fila por fila. Vacía al
      // empezar: la primera subida manda todo, como antes.
      if (desde < 2) await m.createTable(subidas);
    },
    beforeOpen: (detalles) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // El aviso de cierre puede escribir desde segundo plano mientras la
      // app está abierta: se espera en lugar de fallar.
      await customStatement('PRAGMA busy_timeout = 5000');
      // Las categorías nuevas y renombradas llegan también a los teléfonos
      // que ya tenían datos (entrega 14.14).
      await ponerAlDiaCategorias(this, const Uuid().v4);
    },
  );
}
