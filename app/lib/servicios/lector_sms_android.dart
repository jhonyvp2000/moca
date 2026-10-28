import 'package:sms_autofill/sms_autofill.dart';

import '../dominio/cuenta_real.dart';

/// SMS Retriever de Android, sin permiso para leer los mensajes
/// (entrega 14.7).
class LectorSmsAndroid implements LectorCodigoSms {
  final _sms = SmsAutoFill();

  @override
  Future<String?> marca() async {
    try {
      final marca = await _sms.getAppSignature;
      return marca.length == 11 ? marca : null;
    } on Object {
      return null;
    }
  }

  // Solo 6 dígitos seguidos: la marca del final también puede traer cifras.
  @override
  Future<void> esperar() => _sms.listenForCode(smsCodeRegexPattern: r'\d{6}');

  @override
  Stream<String> get codigos => _sms.code;

  @override
  Future<void> dejarDeEsperar() async {
    try {
      await _sms.unregisterListener();
    } on Object {
      // Ya no estaba escuchando.
    }
  }
}
