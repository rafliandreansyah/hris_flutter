plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hroasish.app"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.hroasish.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Host App Links klien custom; default = host prod (duplikat tak berbahaya).
        // Build klien: flutter build apk -- -PcustomHost=app.klien.co.id --dart-define=WEB_BASE_URL=https://app.klien.co.id
        manifestPlaceholders["customHost"] =
            (project.findProperty("customHost") as String?) ?: "app.hroasish.com"

        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    testOptions {
        // Wajib agar clearPackageData berfungsi (state tidak bocor antar test E2E).
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    buildTypes {
        // Non-release: default customHost = host dev (duplikat). Jangan app.hroasish.com, host belum
        // terverifikasi menjatuhkan verifikasi seluruh paket di Android <=11.
        for (name in listOf("debug", "profile")) {
            getByName(name).manifestPlaceholders["customHost"] =
                (project.findProperty("customHost") as String?) ?: "dev.hroasish.com"
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
    // NotificationCompat untuk TrackingBootReceiver
    implementation("androidx.core:core:1.13.1")
    androidTestImplementation("androidx.test:runner:1.5.1")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
