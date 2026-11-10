import 'package:flutter/material.dart';

import '../dominio/modelos.dart';
import '../tema/colores.dart';

/// Los iconos de Moca: Material Icons redondeados, que ya vienen con
/// Flutter (sin dependencias nuevas). Uno por cuenta y por tipo de
/// movimiento; los de categoría van en el paquete de país.
abstract final class Iconos {
  static IconData deCuenta(TipoCuenta cuenta) => switch (cuenta) {
    TipoCuenta.efectivo ||
    TipoCuenta.caja2 ||
    TipoCuenta.caja3 => Icons.payments_rounded,
    TipoCuenta.yape ||
    TipoCuenta.plin ||
    TipoCuenta.bbvaPlin ||
    TipoCuenta.scotiabankPlin ||
    TipoCuenta.sip => Icons.smartphone_rounded,
    TipoCuenta.otra => Icons.account_balance_wallet_rounded,
    TipoCuenta.banco ||
    TipoCuenta.interbank ||
    TipoCuenta.bbva ||
    TipoCuenta.scotiabank ||
    TipoCuenta.otroBanco => Icons.account_balance_rounded,
  };

  /// El color del icono de una cuenta y su fondo: Yape morado y Plin
  /// celeste, porque se reconocen al instante; el resto, azul de marca.
  static (Color, Color) coloresDeCuenta(TipoCuenta cuenta) => switch (cuenta) {
    TipoCuenta.yape => (Colores.yape, Colores.yapeFondo),
    TipoCuenta.plin ||
    TipoCuenta.bbvaPlin ||
    TipoCuenta.scotiabankPlin => (Colores.plin, Colores.plinFondo),
    _ => (Colores.marca, Colores.azul100),
  };

  static IconData deTipo(TipoMovimiento tipo) => switch (tipo) {
    TipoMovimiento.ingreso => Icons.south_west_rounded,
    TipoMovimiento.egreso => Icons.north_east_rounded,
    TipoMovimiento.retiro => Icons.person_rounded,
    TipoMovimiento.aporte => Icons.savings_rounded,
    TipoMovimiento.transferencia => Icons.swap_horiz_rounded,
  };
}
