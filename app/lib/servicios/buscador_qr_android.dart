import 'package:mobile_scanner/mobile_scanner.dart';

import '../dominio/comprobantes.dart';

/// Busca el QR del comprobante dentro de la foto, en el teléfono y sin
/// señal (entrega 14).
class BuscadorQrAndroid implements BuscadorQr {
  final _controlador = MobileScannerController(autoStart: false);

  @override
  Future<String?> buscar(String rutaImagen) async {
    final captura = await _controlador.analyzeImage(
      rutaImagen,
      formats: const [BarcodeFormat.qrCode],
    );
    return captura?.barcodes.firstOrNull?.rawValue;
  }
}
