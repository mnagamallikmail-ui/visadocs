import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "in.provaluer.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "in.provaluer.app"
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appName"] = "Pro Valuer"
    }

    flavorDimensions += "environment"

    productFlavors {
        create("development") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appName"] = "Pro Valuer Dev"
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".stage"
            manifestPlaceholders["appName"] = "Pro Valuer Staging"
        }
        create("production") {
            dimension = "environment"
            manifestPlaceholders["appName"] = "Pro Valuer"
        }
    }

    signingConfigs {
        create("release") {
            val keyAliasProp = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
            val keyPasswordProp = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
            val storePasswordProp = keystoreProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
            val storeFileProp = keystoreProperties.getProperty("storeFile") ?: System.getenv("KEYSTORE_FILE") ?: "upload-keystore.jks"

            if (!keyAliasProp.isNullOrBlank() && !keyPasswordProp.isNullOrBlank() && !storePasswordProp.isNullOrBlank()) {
                val keystoreFile = if (file(storeFileProp).isAbsolute) file(storeFileProp) else file(storeFileProp)
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
                storePassword = storePasswordProp
                storeFile = keystoreFile
            } else {
                throw GradleException("Production release build requires valid release signing credentials (KEY_ALIAS, KEY_PASSWORD, KEYSTORE_PASSWORD, KEYSTORE_FILE). Fallback to debug keystore is strictly prohibited for production release builds.")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    val frontendDir = file("../../frontend")
    if (frontendDir.exists()) {
        source = "../../frontend"
    } else {
        source = "../.."
    }
}
