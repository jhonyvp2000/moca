import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/cobro.dart';
import 'package:moca/dominio/equipo.dart';
import 'package:moca/dominio/modelos.dart';

void main() {
  test('Lee lo que manda el servidor', () {
    final c = Cobro.desdeServidor({
      'estado': 'prueba',
      'hasta': '2026-11-23',
      'dias': 11,
      'porVencer': false,
      'plan': null,
      'precio': 1490,
      'pago': {'yape': '911111111', 'nombre': 'Moca'},
      'respondio': false,
    });
    expect(c.estado, EstadoDelCobro.prueba);
    expect(c.hasta, DateTime(2026, 11, 23));
    expect(c.precioCentimos, 1490);
    expect(c.yape, '911111111');
    expect(c.soloAnotar, isFalse);
    expect(Cobro.desdeServidor(const {}).estado, EstadoDelCobro.sinCobro);
  });

  test('Sin señal, la fecha la pone al día y vence igual', () {
    final c = Cobro.desdeServidor({
      'estado': 'prueba',
      'hasta': '2026-11-23',
      'dias': 11,
    });
    expect(c.alDia(DateTime(2026, 11, 21, 18)).dias, 2);
    expect(c.alDia(DateTime(2026, 11, 21)).porVencer, isTrue);
    expect(c.alDia(DateTime(2026, 11, 23, 23)).estado, EstadoDelCobro.prueba);
    final vencido = c.alDia(DateTime(2026, 11, 24, 8));
    expect(vencido.estado, EstadoDelCobro.vencido);
    expect(vencido.soloAnotar, isTrue);
  });

  test('La pregunta del día 10: con 4 días o menos, una sola vez', () {
    Cobro prueba(int dias, {bool respondio = false}) => Cobro(
      estado: EstadoDelCobro.prueba,
      hasta: DateTime(2026, 11, 23),
      dias: dias,
      respondio: respondio,
    );
    expect(prueba(5).tocaPreguntar, isFalse);
    expect(prueba(4).tocaPreguntar, isTrue);
    expect(prueba(4, respondio: true).tocaPreguntar, isFalse);
    expect(
      const Cobro(estado: EstadoDelCobro.prueba, dias: 14).tocaPreguntar,
      isFalse,
    );
  });

  test('Al vencer se cierran los saldos, el arqueo, los informes y los '
      'avisos; se sigue anotando', () {
    const dueno = Permisos(Rol.dueno, titular: true, soloAnotar: true);
    expect(dueno.anota, isTrue);
    expect(dueno.veSaldos, isFalse);
    expect(dueno.haceArqueo, isFalse);
    expect(dueno.veInformes, isFalse);
    expect(dueno.veAvisos, isFalse);
    expect(dueno.cambiaCuentas, isFalse);
    expect(dueno.gestionaEquipo, isTrue);
    expect(dueno.borraElNegocio, isTrue);
    expect(const Permisos(Rol.dueno).veInformes, isTrue);
  });
}
