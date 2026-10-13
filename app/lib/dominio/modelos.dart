// Tipos del modelo de datos (docs/modelo-datos.md).
// Este archivo no depende de Flutter ni de cómo se guardan los datos.

enum TipoNegocio { bodega, restaurante, servicios, otro }

enum ModoEmpresa { simple, formal }

enum Rol { dueno, contador, empleado }

/// Efectivo, Yape y Banco existen siempre. Plin, Sip y otra billetera (con
/// el nombre que ponga el dueño) solo si el dueño las usa (decisiones.md,
/// 13-10-2026).
enum TipoCuenta {
  efectivo,
  yape,
  banco,
  plin,
  sip,
  otra;

  /// Las cuentas que tiene todo negocio desde la primera venta.
  static const basicas = [efectivo, yape, banco];

  /// Las billeteras que el dueño puede agregar.
  static const billeteras = [plin, sip, otra];

  /// Cómo se muestran: las billeteras junto a Yape y el banco al final.
  static const enOrden = [efectivo, yape, plin, sip, otra, banco];
}

enum TipoContraparte { cliente, proveedor }

/// Ingreso, egreso o retiro del dueño. El retiro baja la caja pero no es gasto.
enum TipoMovimiento { ingreso, egreso, retiro }

enum EstadoPago { pagado, pendiente, parcial }

/// A: verificado contra SUNAT; B: comprobante con QR o foto legible;
/// C: sustento informal; D: declarado sin sustento.
enum NivelConfianza { a, b, c, d }

enum Fuente { voz, texto, foto, qr, sire, arqueo }

/// Nada se borra: un registro se anula y el cambio queda en la bitácora.
enum EstadoRegistro { vigente, anulado }

/// En el prototipo no hay servidor: lo guardado sin conexión queda
/// «por subir» y la marca no cambia (decisiones.md, 12-10-2026).
enum EstadoSincronizacion { subido, porSubir }

enum OrigenLectura { qr, foto, sire }

/// Por qué el conteo no coincide con lo calculado. Retiro, gasto olvidado y
/// venta no anotada generan un movimiento; error de vuelto y «no lo sé»
/// ajustan el saldo sin contar como gasto ni ingreso.
enum MotivoArqueo {
  retiroParaMi,
  gastoOlvidado,
  ventaNoAnotada,
  errorDeVuelto,
  noLoSe,
}

enum PrioridadAlerta { importante, paraTenerEnCuenta }

enum EstadoAlerta { pendiente, vista, resuelta, silenciada }

enum AccionBitacora { crear, editar, anular, pagar, arquear }
