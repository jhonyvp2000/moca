import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../dominio/google_play.dart';

/// La tienda de Google Play en el teléfono (entrega 80), con el paquete
/// in_app_purchase. La compra vuelve por un flujo: se espera la que se pidió.
class TiendaPlayAndroid implements TiendaPlay {
  TiendaPlayAndroid() {
    _escucha = _tienda.purchaseStream.listen(_alLlegar, onError: (_) {});
  }

  final _tienda = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _escucha;
  final _porTerminar = <String, PurchaseDetails>{};
  Completer<CompraEnTienda>? _esperando;
  String? _productoEsperado;

  void _alLlegar(List<PurchaseDetails> compras) {
    for (final c in compras) {
      final token = c.verificationData.serverVerificationData;
      if (c.pendingCompletePurchase) _porTerminar[token] = c;
      final esLaPedida =
          _esperando != null &&
          !_esperando!.isCompleted &&
          c.productID == _productoEsperado;
      if (!esLaPedida) {
        // Una que llegó sola (la que quedó pendiente, o una restaurada): el
        // servidor la conoce por el aviso de Google; aquí solo se cierra.
        if (c.status == PurchaseStatus.purchased ||
            c.status == PurchaseStatus.restored) {
          unawaited(terminar(token));
        }
        continue;
      }
      final r = switch (c.status) {
        PurchaseStatus.purchased ||
        PurchaseStatus.restored => (token: token, fallo: null),
        PurchaseStatus.canceled => (
          token: null,
          fallo: FalloDeTienda.cancelada,
        ),
        PurchaseStatus.pending => (token: null, fallo: FalloDeTienda.pendiente),
        PurchaseStatus.error => (token: null, fallo: FalloDeTienda.fallo),
      };
      _esperando!.complete(r);
    }
  }

  @override
  Future<CompraEnTienda> comprar({
    required ProductoDePlay producto,
    required String negocio,
  }) async {
    if (!await _tienda.isAvailable()) {
      return (token: null, fallo: FalloDeTienda.noDisponible);
    }
    final respuesta = await _tienda.queryProductDetails({producto.producto});
    // Una entrada por cada plan base y oferta de la suscripción.
    GooglePlayProductDetails? elegido;
    for (final d
        in respuesta.productDetails.whereType<GooglePlayProductDetails>()) {
      final i = d.subscriptionIndex;
      final ofertas = d.productDetails.subscriptionOfferDetails;
      if (i == null || ofertas == null) continue;
      final o = ofertas[i];
      if (o.basePlanId == producto.planBase && o.offerId == producto.oferta) {
        elegido = d;
        break;
      }
    }
    if (elegido == null) {
      return (token: null, fallo: FalloDeTienda.noDisponible);
    }
    _esperando = Completer<CompraEnTienda>();
    _productoEsperado = producto.producto;
    final abierta = await _tienda.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(
        productDetails: elegido,
        offerToken: elegido.offerToken,
        // Google lo devuelve como obfuscatedExternalAccountId.
        applicationUserName: negocio,
      ),
    );
    if (!abierta) {
      _esperando = null;
      return (token: null, fallo: FalloDeTienda.fallo);
    }
    return _esperando!.future;
  }

  @override
  Future<void> terminar(String token) async {
    final c = _porTerminar.remove(token);
    if (c == null) return;
    try {
      await _tienda.completePurchase(c);
    } on Object {
      // El servidor ya la reconoció: si la tienda no pudo, no pasa nada.
    }
  }

  Future<void> cerrar() => _escucha.cancel();
}
