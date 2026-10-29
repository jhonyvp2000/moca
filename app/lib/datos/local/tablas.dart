import 'package:drift/drift.dart';

import '../../dominio/modelos.dart';

// Tablas de docs/modelo-datos.md. Reglas comunes:
// - Los identificadores se generan en el teléfono (uuid), para que una subida
//   repetida no duplique registros cuando exista el servidor.
// - Toda tabla de negocio lleva empresa_id.
// - Los montos se guardan en céntimos, como enteros.

mixin _ConId on Table {
  TextColumn get id => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Usuarios extends Table with _ConId {
  TextColumn get celular => text().nullable()();
  TextColumn get nombre => text().nullable()();
  DateTimeColumn get creadoEn => dateTime()();
}

class Empresas extends Table with _ConId {
  TextColumn get nombre => text()();
  TextColumn get tipoNegocio => textEnum<TipoNegocio>()();
  TextColumn get modo => textEnum<ModoEmpresa>()();
  TextColumn get pais => text()();
  TextColumn get moneda => text()();
  TextColumn get regimen => text().nullable()();

  /// Hora de cierre en minutos desde la medianoche (21:00 = 1260).
  IntColumn get horaCierreMinutos => integer()();
  TextColumn get identificacionFiscal => text().nullable()();
  DateTimeColumn get creadoEn => dateTime()();
}

class Membresias extends Table with _ConId {
  TextColumn get usuarioId => text().references(Usuarios, #id)();
  TextColumn get empresaId => text().references(Empresas, #id)();
  TextColumn get rol => textEnum<Rol>()();
}

class Cuentas extends Table with _ConId {
  TextColumn get empresaId => text().references(Empresas, #id)();
  TextColumn get tipo => textEnum<TipoCuenta>()();
  TextColumn get nombre => text()();

  /// Nulo mientras el dueño no declara su saldo inicial.
  IntColumn get saldoInicialCentimos => integer().nullable()();
  DateTimeColumn get fechaSaldoInicial => dateTime().nullable()();
  IntColumn get orden => integer()();
}

class Contrapartes extends Table with _ConId {
  TextColumn get empresaId => text().references(Empresas, #id)();
  TextColumn get nombre => text()();
  TextColumn get identificacionFiscal => text().nullable()();
  TextColumn get tipo => textEnum<TipoContraparte>()();
}

class Comprobantes extends Table with _ConId {
  TextColumn get empresaId => text().references(Empresas, #id)();
  TextColumn get emisorIdentificacion => text().nullable()();
  TextColumn get emisorNombre => text().nullable()();
  TextColumn get tipo => text().nullable()();
  TextColumn get serie => text().nullable()();
  TextColumn get numero => text().nullable()();
  DateTimeColumn get fechaEmision => dateTime().nullable()();
  IntColumn get subtotalCentimos => integer().nullable()();
  IntColumn get impuestoCentimos => integer().nullable()();
  IntColumn get totalCentimos => integer()();
  TextColumn get rutaImagen => text().nullable()();
  TextColumn get origenLectura => textEnum<OrigenLectura>()();
  DateTimeColumn get creadoEn => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {empresaId, emisorIdentificacion, tipo, serie, numero},
  ];
}

class ItemsComprobante extends Table with _ConId {
  TextColumn get comprobanteId => text().references(Comprobantes, #id)();
  TextColumn get descripcion => text()();
  RealColumn get cantidad => real().nullable()();
  IntColumn get precioUnitarioCentimos => integer().nullable()();
  IntColumn get importeCentimos => integer()();
}

class Categorias extends Table with _ConId {
  TextColumn get empresaId => text().references(Empresas, #id)();
  TextColumn get nombre => text()();
  TextColumn get tipoMovimiento => textEnum<TipoMovimiento>()();
  IntColumn get orden => integer()();
  BoolColumn get activa => boolean().withDefault(const Constant(true))();
}

class Movimientos extends Table with _ConId {
  TextColumn get empresaId => text().references(Empresas, #id)();
  TextColumn get tipo => textEnum<TipoMovimiento>()();
  TextColumn get cuentaId => text().references(Cuentas, #id)();
  IntColumn get montoCentimos => integer()();
  DateTimeColumn get fechaMovimiento => dateTime()();
  DateTimeColumn get fechaComprobante => dateTime().nullable()();
  TextColumn get estadoPago => textEnum<EstadoPago>()();
  IntColumn get montoPagadoCentimos => integer()();
  DateTimeColumn get fechaVencimiento => dateTime().nullable()();

  /// Cuándo salió la plata de la cuenta; nulo mientras se debe.
  DateTimeColumn get fechaPago => dateTime().nullable()();
  TextColumn get categoriaId => text().nullable().references(Categorias, #id)();
  TextColumn get contraparteId =>
      text().nullable().references(Contrapartes, #id)();
  TextColumn get comprobanteId =>
      text().nullable().references(Comprobantes, #id)();
  TextColumn get nivelConfianza => textEnum<NivelConfianza>()();
  TextColumn get fuente => textEnum<Fuente>()();
  TextColumn get autorId => text().references(Usuarios, #id)();
  TextColumn get nota => text().nullable()();
  TextColumn get estado => textEnum<EstadoRegistro>()();

  /// En una edición, el movimiento anulado que este reemplaza.
  TextColumn get reemplazaA => text().nullable()();
  TextColumn get estadoSincronizacion => textEnum<EstadoSincronizacion>()();
  DateTimeColumn get creadoEn => dateTime()();
}

class Arqueos extends Table with _ConId {
  TextColumn get empresaId => text().references(Empresas, #id)();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get autorId => text().references(Usuarios, #id)();
  DateTimeColumn get creadoEn => dateTime()();
}

class ArqueoCuentas extends Table with _ConId {
  TextColumn get arqueoId => text().references(Arqueos, #id)();
  TextColumn get cuentaId => text().references(Cuentas, #id)();
  IntColumn get saldoCalculadoCentimos => integer()();
  IntColumn get saldoRealCentimos => integer()();
  IntColumn get diferenciaCentimos => integer()();
  TextColumn get motivo => textEnum<MotivoArqueo>().nullable()();

  /// El movimiento que generó el motivo, si generó uno.
  TextColumn get movimientoId =>
      text().nullable().references(Movimientos, #id)();
}

class Alertas extends Table with _ConId {
  TextColumn get empresaId => text().references(Empresas, #id)();
  TextColumn get tipo => text()();
  TextColumn get prioridad => textEnum<PrioridadAlerta>()();
  TextColumn get estado => textEnum<EstadoAlerta>()();
  TextColumn get texto => text()();

  /// Los datos que dispararon la alerta, en JSON.
  TextColumn get datos => text()();
  DateTimeColumn get creadoEn => dateTime()();
}

class Bitacora extends Table with _ConId {
  TextColumn get empresaId => text().references(Empresas, #id)();
  TextColumn get autorId => text().references(Usuarios, #id)();
  TextColumn get entidad => text()();
  TextColumn get entidadId => text()();
  TextColumn get accion => textEnum<AccionBitacora>()();

  /// Valores en JSON; nulos cuando no aplican (al crear no hay anterior).
  TextColumn get valorAnterior => text().nullable()();
  TextColumn get valorNuevo => text().nullable()();
  DateTimeColumn get fecha => dateTime()();
}

/// Días que el dueño marcó «Hoy no abrí».
class DiasCerrados extends Table with _ConId {
  TextColumn get empresaId => text().references(Empresas, #id)();
  DateTimeColumn get dia => dateTime()();
}

/// Registro local de la medición de la prueba. No guarda montos, nombres ni
/// números de celular.
class EventosMedicion extends Table with _ConId {
  TextColumn get nombre => text()();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get datos => text().nullable()();
}

/// Ajustes sueltos de la app (por ejemplo, si arrancó en Primer día o Demo).
class Ajustes extends Table {
  TextColumn get clave => text()();
  TextColumn get valor => text()();

  @override
  Set<Column<Object>> get primaryKey => {clave};
}

/// Lo que ya está en el servidor, fila por fila (entrega 18): la huella de
/// cada fila tal como se subió o se bajó. Al subir, va solo lo que cambió;
/// así un teléfono con una copia vieja no deshace lo que corrigió otro.
class Subidas extends Table {
  TextColumn get tabla => text()();
  TextColumn get filaId => text()();
  TextColumn get huella => text()();

  @override
  Set<Column<Object>> get primaryKey => {tabla, filaId};
}
