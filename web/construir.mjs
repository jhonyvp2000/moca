// Arma la web para Cloudflare Pages: copia sitio/ a dist/ y pone el número de
// WhatsApp de ventas, que vive solo en la variable WHATSAPP_VENTAS del panel de
// Cloudflare (el repositorio es público). Sin dependencias: node construir.mjs
//
// En los HTML:
//   <!--si-whatsapp--> … <!--sino-whatsapp--> … <!--fin-whatsapp-->
// Con número queda la primera parte, con {{WHATSAPP}} cambiado por el enlace;
// sin número, la segunda (o nada si no hay «sino»).

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const aqui = path.dirname(fileURLToPath(import.meta.url));
const origen = path.join(aqui, "sitio");
const destino = path.join(aqui, "dist");

const mensaje = "Hola, quiero probar Moca.";
const numero = (process.env.WHATSAPP_VENTAS ?? "").replace(/[\s+-]/g, "");

if (numero && !/^51\d{9}$/.test(numero)) {
  console.error("WHATSAPP_VENTAS debe ser 51 y los 9 dígitos del celular, por ejemplo 51987654321.");
  process.exit(1);
}
const enlace = numero ? `https://wa.me/${numero}?text=${encodeURIComponent(mensaje)}` : "";
if (!numero) console.warn("Sin WHATSAPP_VENTAS: los botones llevan al correo de contacto.");

const bloque = /<!--si-whatsapp-->([\s\S]*?)(?:<!--sino-whatsapp-->([\s\S]*?))?<!--fin-whatsapp-->\n?/g;

function procesar(html) {
  const salida = html.replace(bloque, (_, si, sino = "") => (numero ? si : sino));
  return numero ? salida.replaceAll("{{WHATSAPP}}", enlace) : salida;
}

fs.rmSync(destino, { recursive: true, force: true });
fs.cpSync(origen, destino, { recursive: true });

for (const nombre of fs.readdirSync(destino, { recursive: true })) {
  if (!nombre.endsWith(".html")) continue;
  const archivo = path.join(destino, nombre);
  const html = procesar(fs.readFileSync(archivo, "utf8"));
  if (html.includes("{{") || html.includes("whatsapp-->")) {
    console.error(`Quedó un marcador sin reemplazar en ${nombre}.`);
    process.exit(1);
  }
  fs.writeFileSync(archivo, html);
}

console.log(`Listo: dist/ ${numero ? "con" : "sin"} WhatsApp de ventas.`);
