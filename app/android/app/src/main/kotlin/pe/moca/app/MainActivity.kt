package pe.moca.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Base64
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

/**
 * Es una FlutterFragmentActivity porque la huella lo pide (entrega 16.3).
 *
 * Lee solo el SMS del código con SMS Retriever, sin permiso para leer los
 * mensajes (entrega 14.7). Android entrega a Moca el SMS que termina con la
 * marca de la app, y solo si lo envía Google Play Services.
 */
class MainActivity : FlutterFragmentActivity() {
    private var canal: MethodChannel? = null
    private var receptor: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val nuevo = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pe.moca.app/sms")
        canal = nuevo
        nuevo.setMethodCallHandler { llamada, resultado ->
            when (llamada.method) {
                "marca" -> resultado.success(marcaDeLaApp())
                "esperar" -> esperar(resultado)
                "dejar" -> {
                    dejarDeEsperar()
                    resultado.success(null)
                }
                else -> resultado.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        dejarDeEsperar()
        super.onDestroy()
    }

    /** Escucha 5 minutos como máximo. Falso si el teléfono no puede. */
    private fun esperar(resultado: MethodChannel.Result) {
        try {
            SmsRetriever.getClient(this).startSmsRetriever()
                .addOnSuccessListener {
                    registrar()
                    resultado.success(true)
                }
                .addOnFailureListener { resultado.success(false) }
        } catch (e: Exception) {
            resultado.success(false)
        }
    }

    private fun registrar() {
        dejarDeEsperar()
        val nuevo = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action != SmsRetriever.SMS_RETRIEVED_ACTION) return
                val extras = intent.extras ?: return
                if (estado(extras)?.statusCode == CommonStatusCodes.SUCCESS) {
                    val mensaje = extras.getString(SmsRetriever.EXTRA_SMS_MESSAGE)
                    // Solo 6 dígitos seguidos: la marca del final también
                    // puede traer cifras.
                    val codigo = mensaje?.let { Regex("\\d{6}").find(it)?.value }
                    if (codigo != null) canal?.invokeMethod("codigo", codigo)
                }
                dejarDeEsperar()
            }
        }
        val filtro = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
        // Con el permiso de Google Play Services: otra app no puede fingir
        // el SMS.
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(nuevo, filtro, SmsRetriever.SEND_PERMISSION, null, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(nuevo, filtro, SmsRetriever.SEND_PERMISSION, null)
        }
        receptor = nuevo
    }

    private fun estado(extras: Bundle): Status? =
        if (Build.VERSION.SDK_INT >= 33) {
            extras.getParcelable(SmsRetriever.EXTRA_STATUS, Status::class.java)
        } else {
            @Suppress("DEPRECATION")
            extras.get(SmsRetriever.EXTRA_STATUS) as? Status
        }

    private fun dejarDeEsperar() {
        val actual = receptor ?: return
        receptor = null
        try {
            unregisterReceiver(actual)
        } catch (e: IllegalArgumentException) {
            // Ya no estaba registrado.
        }
    }

    /**
     * La marca de 11 caracteres que va al final del SMS: el SHA-256 del
     * nombre del paquete y su firma, en base64 (como AppSignatureHelper de
     * Google). Depende de la llave con que se firmó el APK.
     */
    private fun marcaDeLaApp(): String? = try {
        val firmas = if (Build.VERSION.SDK_INT >= 28) {
            packageManager
                .getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                .signingInfo?.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
        }
        val firma = firmas?.firstOrNull()?.toCharsString()
        if (firma == null) {
            null
        } else {
            val resumen = MessageDigest.getInstance("SHA-256")
                .digest("$packageName $firma".toByteArray(Charsets.UTF_8))
            Base64.encodeToString(resumen.copyOfRange(0, 9), Base64.NO_PADDING or Base64.NO_WRAP)
                .substring(0, 11)
        }
    } catch (e: Exception) {
        null
    }
}
