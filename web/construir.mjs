// Arma la web para Cloudflare Pages: copia sitio/ a dist/ y pone el número de
// WhatsApp de ventas, que vive solo en la variable WHATSAPP_VENTAS del panel de
// Cloudflare (el repositorio es público). Sin dependencias: node construir.mjs
//
// En los HTML:
//   <!--si-whatsapp--> … <!--sino-whatsapp--> … <!--fin-whatsapp-->
// Con número queda la primera parte, con {{WHATSAPP}} cambiado por el enlace;
// sin número, la segunda (o nada si no hay «sino»). Lo mismo con «play» y
// {{PLAY}}, según el enlace de Google Play de más abajo.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const aqui = path.dirname(fileURLToPath(import.meta.url));
const origen = path.join(aqui, "sitio");
const destino = path.join(aqui, "dist");

const mensaje = "Hola, quiero probar Moca.";

// El enlace de Moca en Google Play. Mientras esté vacío, lo que va entre
// <!--si-play--> y <!--fin-play--> no se publica (entrega Web 5).
const enlacePlay = "";
const numero = (process.env.WHATSAPP_VENTAS ?? "").replace(/[\s+-]/g, "");

if (numero && !/^51\d{9}$/.test(numero)) {
  console.error("WHATSAPP_VENTAS debe ser 51 y los 9 dígitos del celular, por ejemplo 51987654321.");
  process.exit(1);
}
const enlace = numero ? `https://wa.me/${numero}?text=${encodeURIComponent(mensaje)}` : "";
if (!numero) console.warn("Sin WHATSAPP_VENTAS: los botones llevan al correo de contacto.");

const bloque = (nombre) =>
  new RegExp(`<!--si-${nombre}-->([\\s\\S]*?)(?:<!--sino-${nombre}-->([\\s\\S]*?))?<!--fin-${nombre}-->\\n?`, "g");

function procesar(html) {
  return html
    .replace(bloque("whatsapp"), (_, si, sino = "") => (numero ? si : sino))
    .replace(bloque("play"), (_, si, sino = "") => (enlacePlay ? si : sino))
    .replaceAll("{{WHATSAPP}}", enlace)
    .replaceAll("{{PLAY}}", enlacePlay);
}

fs.rmSync(destino, { recursive: true, force: true });
fs.cpSync(origen, destino, { recursive: true });

for (const nombre of fs.readdirSync(destino, { recursive: true })) {
  if (!nombre.endsWith(".html")) continue;
  const archivo = path.join(destino, nombre);
  const html = procesar(fs.readFileSync(archivo, "utf8"));
  if (/\{\{|-whatsapp-->|-play-->/.test(html)) {
    console.error(`Quedó un marcador sin reemplazar en ${nombre}.`);
    process.exit(1);
  }
  fs.writeFileSync(archivo, html);
}

console.log(`Listo: dist/ ${numero ? "con" : "sin"} WhatsApp de ventas.`);
