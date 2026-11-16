// Rehace las imágenes de la web con Playwright: node web/imagenes/hacer.cjs
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const aqui = __dirname;
  const sitio = path.join(aqui, '..', 'sitio');
  const b = await chromium.launch();
  for (const [html, png, w, h] of [
    ['compartir.html', 'img/compartir.png', 1200, 630],
    ['icono.html', 'icono-180.png', 180, 180],
  ]) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.goto('file://' + path.join(aqui, html));
    await p.evaluate(() => document.fonts.ready);
    await p.screenshot({ path: path.join(sitio, png) });
    console.log(png);
  }
  await b.close();
})();
