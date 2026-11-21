import type { FastifyInstance } from 'fastify';
import { estiloLegal } from './privacidad.js';

// Cómo pedir que se borre la cuenta (entrega 85): Google Play exige una
// dirección web para pedirlo, aunque la persona ya no tenga la app. Vive
// aquí hasta mudarse a mocanegocios.com. Si cambia cómo se borra en la app
// (Ajustes → Seguridad), se cambia este texto.

const actualizada = '16 de noviembre de 2026';

export function paginaBorrarCuenta(): string {
  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Borrar tu cuenta de Moca</title>
<style>${estiloLegal}</style>
</head>
<body>
<main>
<h1>Borrar tu cuenta de Moca</h1>
<p class="fecha">Última actualización: ${actualizada}</p>
<p>Moca es una app de <strong>Publisher Online E.I.R.L.</strong> (RUC 20572201636). Puedes borrar tu negocio y tus datos cuando quieras, de dos formas.</p>

<h2>Desde la app</h2>
<p>Si eres quien creó el negocio (el titular):</p>
<ol>
<li>En el Inicio, toca el <strong>nombre de tu negocio</strong>, arriba.</li>
<li>Entra a <strong>Seguridad</strong> y toca <strong>«Borrar mi negocio y mis datos»</strong>.</li>
<li>Escribe <strong>BORRAR</strong> y confirma.</li>
</ol>
<p>Se borra al instante y para siempre. Si te invitaron a un negocio de otra persona, en el mismo lugar verás <strong>«Salir de este negocio»</strong>: tu acceso se quita, y lo que anotaste queda en el negocio de quien te invitó.</p>

<h2>Si ya no tienes la app</h2>
<p>Escríbenos a <a href="mailto:contacto@mocanegocios.com?subject=Borrar%20mi%20cuenta%20de%20Moca">contacto@mocanegocios.com</a> con el asunto «Borrar mi cuenta de Moca», el <strong>número de celular</strong> con el que entrabas y el <strong>nombre de tu negocio</strong>. Para confirmar que eres tú, te escribiremos a ese número. Lo borramos en los plazos de la Ley 29733 y te avisamos cuando esté hecho.</p>

<h2>Qué se borra</h2>
<ul>
<li>Tu negocio y todo lo anotado: cuentas, registros, clientes, proveedores, lo que te deben y lo que debes, arqueos e informes.</li>
<li>Las personas de tu equipo pierden el acceso a ese negocio.</li>
<li>Lo que Moca leyó de tus fotos y tu historial de pagos de Moca.</li>
</ul>

<h2>Qué se guarda</h2>
<ul>
<li>Tu <strong>número de celular, sin ningún dato</strong>, para que la prueba gratis no vuelva a empezar con el mismo número.</li>
<li>Los pagos que hiciste por Google Play o Mercado Pago quedan en sus registros, según sus propias reglas. Una suscripción de Google Play se cancela en Google Play, no al borrar el negocio.</li>
<li>Las copias de seguridad se renuevan solas: lo borrado desaparece de ellas en poco tiempo.</li>
</ul>

<p>Más detalles en nuestra <a href="/privacidad">política de privacidad</a>.</p>
</main>
</body>
</html>
`;
}

export function rutasBorrarCuenta(app: FastifyInstance): void {
  app.get('/borrar-cuenta', async (_peticion, respuesta) =>
    respuesta
      .type('text/html; charset=utf-8')
      .header('cache-control', 'public, max-age=3600')
      .send(paginaBorrarCuenta()),
  );
}
