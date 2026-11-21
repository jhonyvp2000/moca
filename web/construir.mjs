// Arma la web para Cloudflare Pages: copia sitio/ a dist/ y llena lo que
// cambia sin tocar el HTML. Sin dependencias: node construir.mjs
//
// En los HTML, un bloque se publica o no según lo que haya:
//   <!--si-X--> … <!--sino-X--> … <!--fin-X-->
// Con X presente queda la primera parte; sin X, la segunda (o nada si no hay
// «sino»). Los X son:
//   whatsapp     el número de ventas, en la variable WHATSAPP_VENTAS del panel de
//                Cloudflare (el repositorio es público). {{WHATSAPP}} es el enlace.
//   play         el enlace de Moca en Google Play (enlacePlay, más abajo), con la
//                insignia oficial en sitio/img/google-play.png. {{PLAY}} es el enlace.
//   video        sitio/video/moca.mp4 y su imagen previa sitio/video/moca.jpg.
//   testimonios  testimonios.json con al menos uno; <!--testimonios--> es la lista.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const aqui = path.dirname(fileURLToPath(import.meta.url));
const origen = path.join(aqui, "sitio");
const destino = path.join(aqui, "dist");

function parar(mensaje) {
  console.error(mensaje);
  process.exit(1);
}

// WhatsApp de ventas.
const mensaje = "Hola, quiero probar Moca.";
const numero = (process.env.WHATSAPP_VENTAS ?? "").replace(/[\s+-]/g, "");
if (numero && !/^51\d{9}$/.test(numero)) {
  parar("WHATSAPP_VENTAS debe ser 51 y los 9 dígitos del celular, por ejemplo 51987654321.");
}
const enlaceWhatsapp = numero ? `https://wa.me/${numero}?text=${encodeURIComponent(mensaje)}` : "";

// Google Play. El enlace no es secreto: va aquí cuando Moca esté publicada,
// por ejemplo "https://play.google.com/store/apps/details?id=pe.moca.app".
// La insignia se baja de la página de insignias de Google Play (en español) y
// se guarda sin cambios como sitio/img/google-play.png.
const enlacePlay = "";
if (enlacePlay) {
  if (!/^https:\/\/play\.google\.com\/store\/apps\/details\?id=[\w.]+$/.test(enlacePlay)) {
    parar("enlacePlay no parece un enlace de Google Play.");
  }
  if (!fs.existsSync(path.join(origen, "img", "google-play.png"))) {
    parar("Falta la insignia oficial de Google Play en sitio/img/google-play.png.");
  }
}

// El video: se publica solo con el MP4 y su imagen previa.
const hayVideo = ["moca.mp4", "moca.jpg"].every((f) => fs.existsSync(path.join(origen, "video", f)));

// Los testimonios: solo de pilotos reales, con su autorización escrita.
const escapar = (texto) =>
  String(texto).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

const testimonios = JSON.parse(fs.readFileSync(path.join(aqui, "testimonios.json"), "utf8"));
if (!Array.isArray(testimonios)) parar("testimonios.json debe ser una lista.");
const listaTestimonios = testimonios
  .map((t, i) => {
    for (const campo of ["frase", "nombre", "negocio", "ciudad"]) {
      if (typeof t[campo] !== "string" || !t[campo].trim()) parar(`Al testimonio ${i + 1} le falta «${campo}».`);
    }
    if (t.autorizacion_escrita !== true) {
      parar(`El testimonio ${i + 1} no tiene «autorizacion_escrita»: true. Sin autorización no se publica.`);
    }
    let retrato = `<span class="testimonio-inicial" aria-hidden="true">${escapar(t.nombre.trim()[0].toUpperCase())}</span>`;
    if (t.foto) {
      if (!/^[\w-]+\.(jpg|png|webp)$/.test(t.foto)) parar(`La foto del testimonio ${i + 1} debe ser un nombre de archivo simple.`);
      if (!fs.existsSync(path.join(origen, "img", "testimonios", t.foto))) parar(`Falta sitio/img/testimonios/${t.foto}.`);
      retrato = `<img src="/img/testimonios/${t.foto}" alt="" width="48" height="48" loading="lazy">`;
    }
    return `        <figure class="testimonio">
          <blockquote>«${escapar(t.frase.trim())}»</blockquote>
          <figcaption>${retrato}<span><strong>${escapar(t.nombre.trim())}</strong><span>${escapar(t.negocio.trim())}, ${escapar(t.ciudad.trim())}</span></span></figcaption>
        </figure>`;
  })
  .join("\n");

const hay = {
  whatsapp: Boolean(numero),
  play: Boolean(enlacePlay),
  video: hayVideo,
  testimonios: testimonios.length > 0,
};

const bloque = (nombre) =>
  new RegExp(`<!--si-${nombre}-->([\\s\\S]*?)(?:<!--sino-${nombre}-->([\\s\\S]*?))?<!--fin-${nombre}-->\\n?`, "g");

function procesar(html) {
  for (const [nombre, presente] of Object.entries(hay)) {
    html = html.replace(bloque(nombre), (_, si, sino = "") => (presente ? si : sino));
  }
  return html
    .replaceAll("{{WHATSAPP}}", enlaceWhatsapp)
    .replaceAll("{{PLAY}}", enlacePlay)
    .replace("<!--testimonios-->", listaTestimonios);
}

fs.rmSync(destino, { recursive: true, force: true });
fs.cpSync(origen, destino, { recursive: true });

for (const nombre of fs.readdirSync(destino, { recursive: true })) {
  if (!nombre.endsWith(".html")) continue;
  const archivo = path.join(destino, nombre);
  const html = procesar(fs.readFileSync(archivo, "utf8"));
  if (/\{\{|<!--(si|sino|fin)-|<!--testimonios-->/.test(html)) parar(`Quedó un marcador sin reemplazar en ${nombre}.`);
  fs.writeFileSync(archivo, html);
}

// Lo que no se publica no se sube: el video sin su imagen previa, por ejemplo.
if (!hayVideo) fs.rmSync(path.join(destino, "video"), { recursive: true, force: true });

const estado = Object.entries(hay).map(([nombre, presente]) => `${nombre} ${presente ? "sí" : "no"}`);
console.log(`Listo: dist/ (${estado.join(", ")}).`);
