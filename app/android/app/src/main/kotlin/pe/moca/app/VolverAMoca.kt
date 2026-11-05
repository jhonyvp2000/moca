package pe.moca.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * «Volver a Moca» desde la página de regreso de Mercado Pago (entrega 32.1).
 *
 * Una pantalla de paso, invisible: abre Moca igual que el ícono y se cierra.
 * MainActivity tiene taskAffinity="": si el enlace la abriera directo, Android
 * podría crear una segunda copia de Moca sin la espera del pago. El intent
 * del ícono, en cambio, siempre trae al frente la Moca que ya estaba abierta.
 */
class VolverAMoca : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        packageManager.getLaunchIntentForPackage(packageName)?.let { moca ->
            moca.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
            startActivity(moca)
        }
        finish()
    }
}
