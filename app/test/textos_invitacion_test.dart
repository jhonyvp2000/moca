import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/textos/textos.dart';

void main() {
  test('El mensaje de la invitación dice qué hacer (entrega 30)', () {
    final con = Textos.mensajeDeInvitacion(
      nombre: 'Rosa',
      negocio: 'Bodega Don Lucho',
      rol: Rol.ayudante,
      celular: '987 654 321',
      vence: '12 de noviembre',
      enlace: 'https://moca-servidor.onrender.com/descargar',
    );
    expect(
      con,
      'Hola Rosa, te invité a Bodega Don Lucho en Moca, como Ayudante.\n'
      '1. Instala Moca desde aquí: '
      'https://moca-servidor.onrender.com/descargar. Si el teléfono '
      'pregunta, permite instalar desde esa fuente.\n'
      '2. Abre Moca, toca «Me invitaron a un negocio» y pon tu número, '
      '987 654 321. Te llega un código por SMS.\n\n'
      'La invitación vale hasta el 12 de noviembre.',
    );
    final sin = Textos.mensajeDeInvitacion(
      nombre: null,
      negocio: 'Bodega Don Lucho',
      rol: Rol.contador,
      celular: '987 654 321',
      vence: '12 de noviembre',
      enlace: 'https://x/descargar',
    );
    expect(sin, startsWith('Hola, te invité a Bodega Don Lucho'));
    expect(sin, contains('como Contador'));
  });
}
