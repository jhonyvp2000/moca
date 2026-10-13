// Tipos del modelo de datos (docs/modelo-datos.md).
// Este archivo no depende de Flutter ni de cómo se guardan los datos.

enum TipoNegocio { bodega, restaurante, servicios, otro }

enum ModoEmpresa { simple, formal }

enum Rol { dueno, contador, empleado }

enum TipoCuenta { efectivo, yape, banco }

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
