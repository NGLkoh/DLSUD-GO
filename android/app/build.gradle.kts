import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.dlsud.go"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as? String
            keyPassword = keyProperties["keyPassword"] as? String
            storeFile = if (keyProperties["storeFile"] != null) rootProject.file(keyProperties["storeFile"] as String) else null
            storePassword = keyProperties["storePassword"] as? String
        }
    }

    // 🚀 FIX FOR 16KB MEMORY PAGE SIZE WARNING
    packagingOptions {
        // Excludes specific native libraries that target non-standard memory page sizes
        exclude("lib/arm64-v8a/libflutter.so")
        exclude("lib/armeabi-v7a/libflutter.so")
        exclude("lib/x86_64/libflutter.so")
        exclude("lib/x86/libflutter.so")
    }
    // ------------------------------------------

    defaultConfig {
        applicationId = "com.dlsud.go"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}