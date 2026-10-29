import 'modelos.dart';

/// Varias personas en un mismo negocio (decisiones.md, 29-10-2026; entregas
/// 17 a 23). Cada una entra con su propio celular, invitada por un dueño.

/// Alguien que está en el negocio.
class PersonaDelEquipo {
  const PersonaDelEquipo({
    required this.membresiaId,
    required this.usuarioId,
    required this.rol,
    this.nombre,
    this.celular,
    this.titular = false,
    this.soyYo = false,
  });

  final String membresiaId;
  final String usuarioId;
  final Rol rol;

  /// Cómo lo llama el negocio («Rosa»); nulo para el titular.
  final String? nombre;

  /// Los 9 dígitos; solo los dueños los ven.
  final String? celular;

  /// Quien creó el negocio: nadie lo quita.
  final bool titular;
  final bool soyYo;
}

/// Una invitación que todavía no se acepta.
class InvitacionPendiente {
  const InvitacionPendiente({
    required this.id,
    required this.celular,
    required this.rol,
    required this.venceEn,
    this.nombre,
  });

  final String id;

  /// Los 9 dígitos.
  final String celular;
  final Rol rol;
  final String? nombre;
  final DateTime venceEn;
}

class Equipo {
  const Equipo({
    required this.miRol,
    required this.maximo,
    required this.personas,
    this.invitaciones = const [],
  });

  final Rol miRol;

  /// Cuántas personas puede tener el negocio, con el titular; el contador
  /// no cuenta.
  final int maximo;
  final List<PersonaDelEquipo> personas;

  /// Solo los dueños las ven.
  final List<InvitacionPendiente> invitaciones;

  bool get soyDueno => miRol == Rol.dueno;

  /// Lugares que quedan para dueños, encargados y ayudantes.
  int get lugaresLibres =>
      maximo -
      personas.where((p) => p.rol != Rol.contador).length -
      invitaciones.where((i) => i.rol != Rol.contador).length;
}

/// Una invitación que le llegó a quien entra por «Me invitaron».
class InvitacionRecibida {
  const InvitacionRecibida({
    required this.id,
    required this.negocio,
    required this.rol,
    required this.venceEn,
    this.nombre,
  });

  final String id;
  final String negocio;
  final Rol rol;
  final String? nombre;
  final DateTime venceEn;
}

enum ResultadoEquipo {
  listo,
  sinSenal,

  /// Ya están las 3 personas.
  sinLugar,

  /// Esa persona ya está en el negocio.
  yaEsta,

  /// Quien acepta ya tiene su propio negocio (salvo el contador).
  yaTieneNegocio,

  /// La invitación venció o la anularon.
  vencida,
  sinPermiso,
  error,
}

/// El equipo en el servidor (servidor/README.md, entrega 17).
abstract interface class ServicioEquipo {
  /// Quiénes están y, para los dueños, las invitaciones. Nulo sin señal o
  /// sin cuenta.
  Future<Equipo?> equipo();

  Future<ResultadoEquipo> invitar({
    required String celular,
    required Rol rol,
    String? nombre,
  });

  Future<ResultadoEquipo> anular(String invitacionId);

  /// Quitar no borra nada: lo que la persona anotó se queda.
  Future<ResultadoEquipo> quitar(String membresiaId);

  /// Las invitaciones que llegaron al entrar por «Me invitaron».
  List<InvitacionRecibida> get invitacionesRecibidas;

  /// Acepta, con el consentimiento de la Ley 29733, y baja lo del negocio
  /// que su rol puede ver.
  Future<ResultadoEquipo> aceptar(String invitacionId);
}

/// Lo que cada rol ve y hace en la app (decisiones.md, 29-10-2026; entrega
/// 20). El servidor lo hace cumplir también: esto solo muestra lo que vale.
class Permisos {
  const Permisos(this.rol);

  static const delDueno = Permisos(Rol.dueno);

  final Rol rol;

  /// El contador solo mira.
  bool get anota => rol != Rol.contador;

  /// «Tienes hoy» y el saldo de cada cuenta. El ayudante ve lo que anotó
  /// hoy (el saldo de su caja llega con las cajas, entrega 21).
  bool get veSaldos => rol != Rol.ayudante;

  bool get veInformes => rol == Rol.dueno || rol == Rol.contador;

  /// Los avisos y el resumen de la semana de la pestaña Moca.
  bool get veAvisos => rol == Rol.dueno || rol == Rol.contador;
  bool get haceArqueo => rol == Rol.dueno || rol == Rol.encargado;
  bool get cambiaCuentas => rol == Rol.dueno;

  /// «Retiro para mí» y «Puse de mi bolsillo» son de la plata del dueño.
  bool get anotaLoDelDueno => rol == Rol.dueno;
  bool get gestionaEquipo => rol == Rol.dueno;

  /// El camino del primer día es del dueño que empieza su negocio.
  bool get tienePrimerDia => rol == Rol.dueno;

  /// El aviso de la hora de cierre y el de cada día.
  bool get recibeAvisos => rol == Rol.dueno;

  /// En el Historial, el ayudante ve solo lo que anotó hoy.
  bool get soloLoDeHoy => rol == Rol.ayudante;

  /// Corregir, deshacer o marcar «Ya lo pagué»: dueños y encargado, todo;
  /// el ayudante, solo lo suyo del día; el contador, nada.
  bool puedeCambiar({required bool deOtro, required bool delDia}) =>
      switch (rol) {
        Rol.dueno || Rol.encargado => true,
        Rol.ayudante => !deOtro && delDia,
        Rol.contador => false,
      };
}
