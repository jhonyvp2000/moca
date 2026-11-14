/// Pagar Moca con Google Play en la versión de Play Store (entrega 80).
///
/// El teléfono abre la compra de Google y le manda al servidor lo que Google
/// le dio (el token). Nunca se le cree al teléfono: el servidor le pregunta a
/// Google y recién ahí Moca queda pagada (`servidor/README.md`).
library;

/// El paquete de Moca en Play Store.
const paqueteDeMoca = 'pe.moca.app';

/// Hasta cuántas personas extra se pagan en Google Play; con más, por
/// WhatsApp. Igual que `servidor/src/google/productos.ts`.
const maximoDeExtrasEnPlay = 5;

/// Lo que se le pide a Google: la suscripción, su plan base y la oferta.
typedef ProductoDePlay = ({String producto, String planBase, String? oferta});

/// El producto de Google de un plan de Moca: «full_2» con «mes» o «anio», y
/// la oferta «fundador». Nulo con más de 5 personas extra.
ProductoDePlay? productoDePlay(String plan, int extras) {
  if (extras < 0 || extras > maximoDeExtrasEnPlay) return null;
  final basico = plan == 'basico' || plan == 'basico_anual';
  final anual = plan == 'anual' || plan == 'basico_anual';
  return (
    producto: '${basico ? 'basico' : 'full'}_$extras',
    planBase: anual ? 'anio' : 'mes',
    oferta: plan == 'fundador' ? 'fundador' : null,
  );
}

/// Donde el dueño ve y cancela sus suscripciones de Google.
String administrarEnGooglePlay(String? producto) =>
    'https://play.google.com/store/account/subscriptions?package=$paqueteDeMoca'
    '${producto == null ? '' : '&sku=$producto'}';

enum FalloDeTienda {
  /// El dueño cerró la hoja de Google.
  cancelada,

  /// Google Play no está o no tiene ese producto.
  noDisponible,

  /// Google la dejó pendiente (pago en efectivo, por ejemplo).
  pendiente,
  fallo,
}

typedef CompraEnTienda = ({String? token, FalloDeTienda? fallo});

/// La tienda de Google; las pruebas la reemplazan.
abstract interface class TiendaPlay {
  /// Abre la compra de Google con el id del negocio, para que la compra no
  /// sirva para otro. Devuelve el token de la compra.
  Future<CompraEnTienda> comprar({
    required ProductoDePlay producto,
    required String negocio,
  });

  /// Le dice a Google que la compra se entregó (el servidor ya lo hizo; esto
  /// le avisa a la tienda del teléfono).
  Future<void> terminar(String token);
}

enum ErrorCompraGoogle { sinSenal, otroNegocio, noVigente, noDisponible, fallo }

typedef ResultadoCompraGoogle = ({DateTime? hasta, ErrorCompraGoogle? error});
