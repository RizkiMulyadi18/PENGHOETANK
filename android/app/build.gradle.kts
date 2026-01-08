plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pawang_pinjol"
    compileSdk = 36  //
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ PAKAI TANDA SAMA DENGAN (=)
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Syntax Kotlin wajib pakai "is" dan "="
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.pawang_pinjol"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        minSdk = flutter.minSdkVersion
        targetSdk = 36
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Syntax Kotlin wajib pakai kurung ("...")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
    
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.0") 
    // atau biarkan implementation lain jika sudah ada, tapi pastikan pakai kurung
}
