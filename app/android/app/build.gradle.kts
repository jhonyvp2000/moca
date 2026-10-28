import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Llave de firma de Moca. Todas las versiones del APK deben firmarse con la
// misma llave; si no, una actualización obliga a desinstalar y se pierden los
// datos del teléfono. La llave nunca se sube al repositorio: se lee de
// android/key.properties (en una PC) o la escribe GitHub Actions desde sus secretos.
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
val tieneLlave = keyPropertiesFile.exists()
if (tieneLlave) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "pe.moca.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Las notificaciones programadas (aviso de cierre) lo necesitan en
        // versiones antiguas de Android.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "pe.moca.app"
        // Android 7.0 o superior (decidido el 12-10-2026).
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (tieneLlave) {
            create("moca") {
                storeFile = rootProject.file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Sin llave, se firma con la de depuración: sirve para probar,
            // pero ese APK no se puede actualizar con uno firmado con la llave de Moca.
            signingConfig = if (tieneLlave) {
                signingConfigs.getByName("moca")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // SMS Retriever: el código del SMS se escribe solo (entrega 14.7).
    implementation("com.google.android.gms:play-services-auth-api-phone:18.1.0")
}
