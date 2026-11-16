# La llave pública de cifrado de Google Play

Aquí va `encryption_public_key.pem`, el archivo que da la Play Console al elegir **«Exportar y subir una llave desde un almacén de claves Java»** en la firma de la app (Play App Signing). Es **pública**: sirve para cifrar la llave de Moca de modo que solo Google pueda abrirla. La usa el flujo `.github/workflows/llave-play.yml` (entrega 84). Paso a paso: `docs/guia-google-play.md`, paso 1.3.
