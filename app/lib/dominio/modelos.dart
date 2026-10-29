// Tipos del modelo de datos (docs/modelo-datos.md).
// Este archivo no depende de Flutter ni de cómo se guardan los datos.

enum TipoNegocio { bodega, restaurante, servicios, otro }

enum ModoEmpresa { simple, formal }

/// Quién es en el negocio (decisiones.md, 29-10-2026; entrega 17).
enum Rol { dueno, encargado, ayudante, contador }

/// Efectivo, Yape y el BCP (`banco`) existen siempre. Plin, Sip y otra
/// billetera, y los otros bancos (Interbank, BBVA, Scotiabank y otro banco o
/// caja), solo si el dueño los usa. La otra billetera y el otro banco llevan
/// el nombre que ponga el dueño (decisiones.md, 13-10-2026 y 15-10-2026).
enum TipoCuenta {
  efectivo,

  /// Otras cajas de efectivo, con el nombre que les ponga el dueño («Caja
  /// delivery»); la principal sigue siendo [efectivo] (entrega 21).
  caja2,
  caja3,
  yape,

  /// El BCP. Se llamaba «Banco» hasta la entrega 14.1.
  banco,
  plin,
  sip,
  otra,
  interbank,
  bbva,
  scotiabank,
  otroBanco,

  /// Plin de BBVA y de Scotiabank, aparte del de Interbank (`plin`)
  /// (entrega 14.10).
  bbvaPlin,
  scotiabankPlin;

  /// Las cuentas que tiene todo negocio desde la primera venta.
  static const basicas = [efectivo, yape, banco];

  /// Las cajas de efectivo: la principal y hasta dos más (entrega 21).
  static const cajas = [efectivo, caja2, caja3];

  /// Las billeteras que el dueño puede agregar.
  static const billeteras = [plin, bbvaPlin, scotiabankPlin, sip, otra];

  /// Los bancos que el dueño puede agregar además del BCP.
  static const otrosBancos = [interbank, bbva, scotiabank, otroBanco];

  /// Todo lo que se puede agregar después del alta, con las otras cajas
  /// (entrega 21).
  static const agregables = [...billeteras, ...otrosBancos, caja2, caja3];

  /// Cómo se muestran: las billeteras junto a Yape y los bancos al final.
  static const enOrden = [
    efectivo,
    caja2,
    caja3,
    yape,
    plin,
    bbvaPlin,
    scotiabankPlin,
    sip,
    otra,
    banco,
    interbank,
    bbva,
    scotiabank,
    otroBanco,
  ];

  bool get esBanco => this == banco || otrosBancos.contains(this);

  bool get esCaja => cajas.contains(this);

  /// Las billeteras Plin: si el dueño dice «por Plin» y tiene más de una,
  /// Moca pregunta cuál (entrega 14.10).
  bool get esPlin => this == plin || this == bbvaPlin || this == scotiabankPlin;

  /// La cuenta que lleva el nombre que escribe el dueño.
  bool get conNombrePropio =>
      this == otra || this == otroBanco || this == caja2 || this == caja3;
}

enum TipoContraparte { cliente, proveedor }

/// Ingreso, egreso o retiro del dueño. El retiro baja la caja pero no es gasto.
enum TipoMovimiento {
  ingreso,
  egreso,
  retiro,

  /// Plata que el dueño puso de su bolsillo (entrega 14.11): sube la plata
  /// del negocio, pero no es venta. Lo contrario del retiro.
  aporte,

  /// «Pasé plata de una caja a otra» (entrega 21.1): sale de una cuenta y
  /// entra a otra del mismo negocio. No es venta ni gasto y el total no
  /// cambia. Depositar en el banco es esto mismo.
  transferencia;

  /// Lo que sube la plata del negocio: lo que entró y lo que puso el dueño.
  bool get entraPlata => this == ingreso || this == aporte;

  /// Plata entre el dueño y el negocio: no lleva categoría ni es venta ni
  /// gasto.
  bool get delDueno => this == retiro || this == aporte;

  /// Plata que solo cambia de cuenta: tampoco lleva categoría.
  bool get esPase => this == transferencia;

  /// Sin categoría: lo del dueño y los pases.
  bool get sinCategoria => delDueno || esPase;
}

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

  /// Sobra plata porque el dueño la puso (entrega 14.11).
  puseYo,
  gastoOlvidado,
  ventaNoAnotada,
  errorDeVuelto,
  noLoSe,
}

enum PrioridadAlerta { importante, paraTenerEnCuenta }

enum EstadoAlerta { pendiente, vista, resuelta, silenciada }

enum AccionBitacora { crear, editar, anular, pagar, arquear }
