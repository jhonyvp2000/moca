import 'modelos.dart';

/// Una de las lecturas posibles que da el reconocimiento de voz. La
/// confianza va de 0 a 1; es nula cuando el teléfono no la informa.
class AlternativaVoz {
  const AlternativaVoz(this.texto, [this.confianza]);

  final String texto;
  final double? confianza;
}

/// Un monto dicho, con la cuenta si se dijo.
class PartidaVoz {
  const PartidaVoz(
    this.centimos, [
    this.cuenta,
    this.bancoSinNombre = false,
    this.plinSinBanco = false,
  ]);

  final int centimos;
  final TipoCuenta? cuenta;

  /// Dijo «banco», «transferencia» o «tarjeta» sin decir cuál: va al BCP,
  /// salvo que el negocio tenga más de un banco (entonces se pregunta).
  final bool bancoSinNombre;

  /// Dijo «Plin» sin decir de qué banco: va al único Plin del negocio; si
  /// tiene más de uno, se pregunta (entrega 14.10).
  final bool plinSinBanco;

  PartidaVoz conCuenta(TipoCuenta cuenta) => PartidaVoz(centimos, cuenta);
}

/// Lo que Moca entendió de una frase. Lo que falta, Moca lo pregunta:
/// nunca adivina un monto.
class LecturaVoz {
  const LecturaVoz({
    required this.textoDicho,
    this.tipo,
    this.partidas = const [],
    this.montosPosibles = const [],
    this.categoria,
    this.prestamo = false,
  });

  static const vacia = LecturaVoz(textoDicho: '');

  final String textoDicho;

  /// Nulo si no se sabe si entró o salió plata.
  final TipoMovimiento? tipo;
  final List<PartidaVoz> partidas;

  /// Si hay duda sobre el monto, las opciones para preguntar (S18).
  final List<int> montosPosibles;

  /// Nombre de la categoría reconocida, si se reconoció.
  final String? categoria;

  /// Dijo que le prestaron plata: Moca avisa que no es venta (entrega
  /// 14.14).
  final bool prestamo;

  bool get montoDudoso => montosPosibles.isNotEmpty;
  bool get entendida => partidas.isNotEmpty || montoDudoso;
}

sealed class EventoVoz {
  const EventoVoz();
}

/// Lo que va reconociendo mientras el dueño habla.
class VozParcial extends EventoVoz {
  const VozParcial(this.texto);

  final String texto;
}

/// El dueño terminó de hablar.
class VozFinal extends EventoVoz {
  const VozFinal(this.alternativas);

  final List<AlternativaVoz> alternativas;
}

enum FalloVoz { sinPermiso, noDisponible, nadaQueEscuchar }

class VozFallida extends EventoVoz {
  const VozFallida(this.motivo);

  final FalloVoz motivo;
}

/// Una frase que el operador de la prueba usa en lugar de la voz.
class FraseEjemplo {
  const FraseEjemplo(this.alternativas);

  /// La primera es la que «se escuchó»; las demás, otras lecturas posibles.
  final List<AlternativaVoz> alternativas;

  String get texto => alternativas.first.texto;
}

enum DisponibilidadVoz { disponible, sinPermiso, noDisponible }

/// El reconocimiento de voz. En el prototipo es el de Android; para la
/// prueba, el operador puede reemplazar la próxima grabación por una frase de
/// ejemplo.
abstract interface class ReconocedorVoz {
  /// Pide el permiso del micrófono si hace falta.
  Future<DisponibilidadVoz> preparar();

  /// Escucha hasta que el dueño calla unos segundos o se llama a [detener].
  Stream<EventoVoz> escuchar();

  Future<void> detener();
}

/// Lo que Moca pregunta, en orden, hasta tener todo para guardar.
sealed class PreguntaVoz {
  const PreguntaVoz();
}

/// S18: no escuchó bien el monto.
class PreguntaMonto extends PreguntaVoz {
  const PreguntaMonto(this.opciones);

  final List<int> opciones;
}

class PreguntaTipo extends PreguntaVoz {
  const PreguntaTipo();
}

class PreguntaCuenta extends PreguntaVoz {
  const PreguntaCuenta(this.indicePartida);

  final int indicePartida;
}

class PreguntaCategoria extends PreguntaVoz {
  const PreguntaCategoria();
}

/// Qué falta preguntar. Nulo si ya está todo. [categoriasValidas] y
/// [cuentasValidas] son las del negocio: una categoría o una cuenta
/// reconocida que el negocio no tiene se pregunta («por Plin» sin Plin).
PreguntaVoz? siguientePregunta(
  LecturaVoz lectura, {
  required Set<String> categoriasValidas,
  Set<TipoCuenta> cuentasValidas = const {...TipoCuenta.values},
}) {
  if (lectura.montoDudoso) return PreguntaMonto(lectura.montosPosibles);
  if (lectura.tipo == null) return const PreguntaTipo();
  final variosBancos = cuentasValidas.where((c) => c.esBanco).length > 1;
  final variosPlin = cuentasValidas.where((c) => c.esPlin).length > 1;
  for (final (i, partida) in lectura.partidas.indexed) {
    if (!cuentasValidas.contains(partida.cuenta) ||
        (partida.bancoSinNombre && variosBancos) ||
        (partida.plinSinBanco && variosPlin)) {
      return PreguntaCuenta(i);
    }
  }
  if (!(lectura.tipo?.delDueno ?? false) &&
      !categoriasValidas.contains(lectura.categoria)) {
    return const PreguntaCategoria();
  }
  return null;
}

extension RespuestasVoz on LecturaVoz {
  LecturaVoz _con({
    TipoMovimiento? tipo,
    List<PartidaVoz>? partidas,
    List<int>? montosPosibles,
    String? categoria,
  }) => LecturaVoz(
    textoDicho: textoDicho,
    tipo: tipo ?? this.tipo,
    partidas: partidas ?? this.partidas,
    montosPosibles: montosPosibles ?? this.montosPosibles,
    categoria: categoria ?? this.categoria,
    prestamo: prestamo,
  );

  /// El dueño eligió o escribió el monto: queda una sola partida, con la
  /// cuenta que se haya dicho.
  LecturaVoz conMonto(int centimos) => _con(
    partidas: [
      PartidaVoz(centimos, partidas.isEmpty ? null : partidas.first.cuenta),
    ],
    montosPosibles: const [],
  );

  LecturaVoz conTipo(TipoMovimiento tipo) => _con(tipo: tipo);

  LecturaVoz conCuenta(int indicePartida, TipoCuenta cuenta) => _con(
    partidas: [
      for (final (i, p) in partidas.indexed)
        i == indicePartida ? p.conCuenta(cuenta) : p,
    ],
  );

  LecturaVoz conCategoria(String categoria) => _con(categoria: categoria);

  /// «Por Plin» sin banco va al único Plin que tenga el negocio.
  LecturaVoz conPlinDelNegocio(Set<TipoCuenta> cuentas) {
    final plin = cuentas.where((c) => c.esPlin).toList();
    if (plin.length != 1) return this;
    return _con(
      partidas: [
        for (final p in partidas) p.plinSinBanco ? p.conCuenta(plin.single) : p,
      ],
    );
  }
}
