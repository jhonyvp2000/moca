import '../../dominio/voz.dart';

/// Frases que el operador de la prueba puede usar en lugar de la voz, cuando
/// el teléfono no reconoce voz o para probar un caso concreto.
const frasesEjemplo = [
  FraseEjemplo([AlternativaVoz('Hoy vendí 350 en efectivo y 120 por Yape')]),
  FraseEjemplo([AlternativaVoz('En efectivo, trescientos cincuenta')]),
  FraseEjemplo([AlternativaVoz('Vendí 480')]),
  FraseEjemplo([AlternativaVoz('Pagué 80 de luz en efectivo')]),
  FraseEjemplo([AlternativaVoz('Compré mercadería por 950 con Yape')]),
  FraseEjemplo([AlternativaVoz('Saqué 100 para mí del efectivo')]),
  // Monto dudoso (S18).
  FraseEjemplo([
    AlternativaVoz('Pagué trescientos quince de mercadería', 0.42),
    AlternativaVoz('Pagué trescientos cincuenta de mercadería', 0.38),
  ]),
  // Moca no entiende.
  FraseEjemplo([AlternativaVoz('Hola, ¿cómo estás?')]),
];

/// Devuelve la frase elegida como si se hubiera escuchado.
class ReconocedorFrase implements ReconocedorVoz {
  ReconocedorFrase(this.frase);

  final FraseEjemplo frase;

  @override
  Future<DisponibilidadVoz> preparar() async => DisponibilidadVoz.disponible;

  @override
  Stream<EventoVoz> escuchar() async* {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    yield VozParcial(frase.texto);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    yield VozFinal(frase.alternativas);
  }

  @override
  Future<void> detener() async {}
}
