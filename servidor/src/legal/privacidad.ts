import type { FastifyInstance } from "fastify";

// La política de privacidad (13-11-2026, pagina-web.md 8.2): Play Store la
// pide en una dirección pública. Vive aquí hasta que mocanegocios.com esté
// publicada; luego se muda allá. La revisa un abogado antes de abrir Moca a
// todos. Si cambia lo que Moca hace con los datos, se cambia este texto.

export const actualizada = "14 de noviembre de 2026";

const secciones: [string, string[]][] = [
  [
    "Quién es responsable de tus datos",
    [
      "Moca («Mi Organización Contable Asistida») es una app de <strong>Publisher Online E.I.R.L.</strong> (RUC 20572201636), con domicilio en Jr. 1 de Abril 383, La Banda de Shilcayo, San Martín, Perú.",
      'Para cualquier consulta sobre tus datos, escríbenos a <a href="mailto:contacto@mocanegocios.com">contacto@mocanegocios.com</a>.',
      "Tratamos tus datos según la Ley 29733, Ley de Protección de Datos Personales, y su reglamento.",
    ],
  ],
  [
    "Qué datos usamos",
    [
      "<strong>Tu cuenta:</strong> tu número de celular, que verificamos con un código por SMS o WhatsApp, y el nombre que pongas.",
      "<strong>Tu negocio:</strong> su nombre y tipo, tus cuentas (efectivo, Yape, banco) y lo que anotas en ellas: montos, fechas, categorías, notas, clientes, proveedores, documentos, lo que te deben, lo que debes y tus arqueos.",
      "<strong>Tu equipo:</strong> el celular y el nombre de las personas que invitas a tu negocio. Cada una acepta la invitación antes de entrar.",
      "<strong>Tus clientes:</strong> si anotas el celular de un cliente para recordarle lo que te debe. El recordatorio lo envías tú, desde tu WhatsApp.",
      "<strong>Fotos de comprobantes:</strong> cuando le pides a Moca que lea una foto, la enviamos a nuestro servidor y a un servicio de inteligencia artificial para leer los datos. No guardamos la foto: guardamos lo que se leyó y tú lo confirmas antes de anotarlo.",
      "<strong>Tu voz:</strong> cuando le dictas a Moca, el reconocimiento lo hace el servicio de voz de tu teléfono Android. Moca recibe el texto, no el audio.",
      "<strong>Las preguntas a Moca:</strong> tu pregunta y las cifras ya calculadas de tu negocio se envían al servicio de inteligencia artificial para redactar la respuesta. No guardamos el texto de tus preguntas.",
      "<strong>Tus pagos de Moca:</strong> el plan, las fechas y el monto. Si pagas con Mercado Pago o Google Play, ellos procesan el pago: no recibimos los datos de tu tarjeta. Si yapeas, guardamos el número de operación.",
      "<strong>Uso y errores de la app:</strong> qué pantallas y funciones se usan, sin montos, y los errores técnicos, para corregirlos. Los errores se borran a los 90 días.",
    ],
  ],
  [
    "Para qué los usamos",
    [
      "Para que Moca funcione: guardar y sincronizar tus registros entre tus teléfonos y los de tu equipo, calcular tus saldos e informes, leer tus comprobantes, responder tus preguntas y cobrar tu plan.",
      "Para darte soporte cuando nos lo pides y para mejorar la app.",
      "<strong>No vendemos tus datos ni los usamos para publicidad.</strong>",
    ],
  ],
  [
    "Con quién los compartimos",
    [
      "Solo con los servicios que Moca necesita para funcionar, que los tratan por encargo nuestro:",
      "<strong>Render</strong> (servidores y base de datos, en Estados Unidos) · <strong>Twilio</strong> (códigos por SMS y WhatsApp, Estados Unidos) · <strong>Anthropic</strong> (inteligencia artificial que lee las fotos y redacta las respuestas, Estados Unidos) · <strong>Mercado Pago</strong> y <strong>Google Play</strong> (pagos) · <strong>Google</strong> (el reconocimiento de voz de tu teléfono).",
      "Algunos de estos servicios están fuera del Perú. Al usar Moca, aceptas que tus datos se envíen a ellos para lo descrito aquí.",
      "Dentro de tu negocio, cada persona ve según su rol: dueño, encargado, ayudante o contador. Lo que un rol no puede ver no llega a su teléfono.",
      "Solo entregaríamos tus datos a una autoridad si la ley nos obliga.",
    ],
  ],
  [
    "Cuánto tiempo los guardamos",
    [
      "Mientras tengas tu cuenta. Si dejas de pagar, lo anotado no se borra.",
      "El titular puede borrar su negocio desde la app, en Ajustes. Se borra para siempre, con todos sus registros. Las copias de seguridad se renuevan solas y lo borrado desaparece de ellas en poco tiempo.",
    ],
  ],
  [
    "Tus derechos",
    [
      'Puedes pedir acceder a tus datos, corregirlos, cancelarlos u oponerte a su uso (derechos ARCO), escribiendo a <a href="mailto:contacto@mocanegocios.com">contacto@mocanegocios.com</a> desde el celular o el correo con que te identifiques. Te respondemos en los plazos de la ley.',
      "Si no estás conforme con nuestra respuesta, puedes acudir a la Autoridad Nacional de Protección de Datos Personales del Ministerio de Justicia y Derechos Humanos.",
    ],
  ],
  [
    "Cómo los cuidamos",
    [
      "La conexión entre tu teléfono y nuestro servidor va cifrada. Los datos de cada negocio están separados de los demás en la base de datos. En tu teléfono puedes pedir la huella o la clave para abrir Moca.",
    ],
  ],
  [
    "Menores de edad",
    [
      "Moca es para dueños y trabajadores de negocios mayores de 18 años. No está dirigida a menores.",
    ],
  ],
  [
    "Cambios a esta política",
    [
      "Si cambiamos cómo usamos tus datos, actualizaremos esta página y su fecha, y te avisaremos en la app si el cambio es importante.",
    ],
  ],
];

export function paginaPrivacidad(): string {
  const cuerpo = secciones
    .map(
      ([titulo, parrafos]) =>
        `<h2>${titulo}</h2>\n${parrafos.map((p) => `<p>${p}</p>`).join("\n")}`,
    )
    .join("\n");
  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Política de privacidad de Moca</title>
<style>
:root{--marca:#1D4ED8;--texto:#13213F;--suave:#4A5878;--fondo:#F4F7FC;--superficie:#FFFFFF}
body{margin:0;background:var(--fondo);color:var(--texto);font:16px/1.6 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
main{max-width:720px;margin:0 auto;padding:32px 16px 64px;background:var(--superficie)}
h1{font-size:28px;line-height:1.25;margin:0 0 4px;color:var(--marca)}
h2{font-size:20px;margin:32px 0 8px}
p{margin:0 0 12px}
.fecha{color:var(--suave);font-size:14px;margin-bottom:24px}
a{color:var(--marca)}
</style>
</head>
<body>
<main>
<h1>Política de privacidad de Moca</h1>
<p class="fecha">Última actualización: ${actualizada}</p>
<p>Tú vendes. Moca hace las cuentas. Para eso, Moca usa datos tuyos y de tu negocio. Aquí te contamos cuáles, para qué y qué puedes hacer con ellos.</p>
${cuerpo}
</main>
</body>
</html>
`;
}

export function rutasPrivacidad(app: FastifyInstance): void {
  app.get("/privacidad", async (_peticion, respuesta) =>
    respuesta
      .type("text/html; charset=utf-8")
      .header("cache-control", "public, max-age=3600")
      .send(paginaPrivacidad()),
  );
}
