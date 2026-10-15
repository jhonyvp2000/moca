// Tipos del modelo de datos (docs/modelo-datos.md).
// Este archivo no depende de Flutter ni de cómo se guardan los datos.

enum TipoNegocio { bodega, restaurante, servicios, otro }

enum ModoEmpresa { simple, formal }

enum Rol { dueno, contador, empleado }

/// Efectivo, Yape y el BCP (`banco`) existen siempre. Plin, Sip y otra
/// billetera, y los otros bancos (Interbank, BBVA, Scotiabank y otro banco o
/// caja), solo si el dueño los usa. La otra billetera y el otro banco llevan
/// el nombre que ponga el dueño (decisiones.md, 13-10-2026 y 15-10-2026).
enum TipoCuenta {
  efectivo,
  yape,

  /// El BCP. Se llamaba «Banco» hasta la entrega 14.1.
  banco,
  plin,
  sip,
  otra,
  interbank,
  bbva,
  scotiabank,
  otroBanco;

  /// Las cuentas que tiene todo negocio desde la primera venta.
  static const basicas = [efectivo, yape, banco];

  /// Las billeteras que el dueño puede agregar.
  static const billeteras = [plin, sip, otra];

  /// Los bancos que el dueño puede agregar además del BCP.
  static const otrosBancos = [interbank, bbva, scotiabank, otroBanco];

  /// Todo lo que se puede agregar después del alta.
  static const agregables = [...billeteras, ...otrosBancos];

  /// Cómo se muestran: las billeteras junto a Yape y los bancos al final.
  static const enOrden = [
    efectivo,
    yape,
    plin,
    sip,
    otra,
    banco,
    interbank,
    bbva,
    scotiabank,
    otroBanco,
  ];

  bool get esBanco => this == banco || otrosBancos.contains(this);

  /// La cuenta que lleva el nombre que escribe el dueño.
  bool get conNombrePropio => this == otra || this == otroBanco;
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
