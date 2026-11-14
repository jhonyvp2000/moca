import { describe, expect, it } from "vitest";
import { crearApp } from "../src/app.js";
import type { Pool } from "../src/base/conexion.js";

describe("GET /privacidad", () => {
  it("Publica la política de privacidad en una dirección pública, sin cuenta", async () => {
    const app = crearApp({ pool: {} as Pool, version: "0.10.0" });
    const respuesta = await app.inject({ method: "GET", url: "/privacidad" });
    expect(respuesta.statusCode).toBe(200);
    expect(respuesta.headers["content-type"]).toContain("text/html");
    const html = respuesta.body;
    expect(html).toContain("Publisher Online E.I.R.L.");
    expect(html).toContain("contacto@mocanegocios.com");
    expect(html).toContain("Ley 29733");
    for (const servicio of [
      "Render",
      "Twilio",
      "Anthropic",
      "Mercado Pago",
      "Google Play",
    ]) {
      expect(html).toContain(servicio);
    }
    await app.close();
  });
});
