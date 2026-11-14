import { accesoDeGoogle, ErrorDeGoogle, leerCuentaDeServicio } from './cliente.js';
import { suscripcionesDeMoca } from './suscripciones.js';

// Crea o pone al día las 12 suscripciones de Moca en Google Play (entrega 81)
// y activa sus planes base. Se corre una vez, en el Shell de Render (donde
// está GOOGLE_PLAY_CUENTA_SERVICIO), después de subir el primer AAB a la
// Play Console:   npm run suscripciones-play
// Volver a correrlo no duplica nada: actualiza las que ya existen.

const versionDeRegiones = '2022/02';

export async function crearSuscripciones(
  pedir: ReturnType<typeof accesoDeGoogle>,
  decir: (linea: string) => void = console.log,
): Promise<void> {
  for (const s of suscripcionesDeMoca()) {
    const ruta = `/subscriptions/${s.productId}`;
    let existe = true;
    try {
      await pedir(ruta);
    } catch (error) {
      if (!(error instanceof ErrorDeGoogle) || error.estado !== 404) throw error;
      existe = false;
    }
    const version = `regionsVersion.version=${encodeURIComponent(versionDeRegiones)}`;
    if (existe) {
      await pedir(`${ruta}?updateMask=listings,basePlans&${version}`, 'PATCH', s);
    } else {
      await pedir(`/subscriptions?productId=${s.productId}&${version}`, 'POST', s);
    }
    for (const b of s.basePlans) {
      try {
        await pedir(`${ruta}/basePlans/${b.basePlanId}:activate`, 'POST', {});
      } catch (error) {
        // Ya activo: Google responde 400 y no pasa nada.
        if (!(error instanceof ErrorDeGoogle) || error.estado !== 400) throw error;
      }
    }
    decir(`${existe ? 'Al día' : 'Creada'}: ${s.productId} (${s.basePlans.map((b) => b.basePlanId).join(', ')})`);
  }
}

// Solo al correrlo como programa, no al importarlo en las pruebas.
if (process.argv[1]?.endsWith('crear_suscripciones.js')) {
  const cuenta = leerCuentaDeServicio();
  if (!cuenta) {
    console.error('Falta GOOGLE_PLAY_CUENTA_SERVICIO.');
    process.exit(1);
  }
  await crearSuscripciones(accesoDeGoogle(cuenta));
  console.log('Listo: las 12 suscripciones de Moca están en Google Play.');
}
