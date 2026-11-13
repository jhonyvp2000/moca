import 'package:flutter_test/flutter_test.dart';
import 'package:moca/dominio/informe.dart';
import 'package:moca/dominio/modelos.dart';
import 'package:moca/pais/peru/categorias.dart';
import 'package:moca/textos/textos.dart';

void main() {
  test(
    'Entrega 48: cada tipo de negocio tiene nombre y categorías propias',
    () {
      for (final tipo in TipoNegocio.values) {
        expect(Textos.nombreTipoNegocio(tipo), isNotEmpty, reason: tipo.name);
        expect(categoriasEgresoPorNegocio[tipo], isNotEmpty, reason: tipo.name);
      }
      // Lo que se compra para vender cuenta como mercadería, también en el
      // flujo para la caja.
      for (final nombre in categoriasDeMercaderia) {
        expect(filaDelFlujo[nombre], FilaFlujo.mercaderia, reason: nombre);
      }
      expect(categoriasEgresoPorNegocio[TipoNegocio.farmacia], [
        'Medicamentos y productos',
        'Bolsas y envases',
      ]);
      expect(filaDelFlujo['Repuestos'], FilaFlujo.mantenimiento);
    },
  );
}
