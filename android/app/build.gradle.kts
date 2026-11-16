import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.example.peluna"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.peluna"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                val storeFilePath =
                    keystoreProperties.getProperty("storeFile")
                        ?: error("storeFile is missing from android/key.properties")
                val keyAliasValue =
                    keystoreProperties.getProperty("keyAlias")
                        ?: error("keyAlias is missing from android/key.properties")
                val storePasswordValue =
                    keystoreProperties.getProperty("storePassword")
                        ?: error("storePassword is missing from android/key.properties")
                val keyPasswordValue =
                    keystoreProperties.getProperty("keyPassword")
                        ?: error("keyPassword is missing from android/key.properties")

                storeFile = file(storeFilePath)
                storePassword = storePasswordValue
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
                storeType = keystoreProperties.getProperty("storeType") ?: "jks"
            }
        }
    }

    buildTypes {
        release {
            // CI uses android/key.properties and the release keystore. Without
            // those files, fall back to the debug key so local builds still work.
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
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

dependencies {
    implementation("androidx.core:core-ktx:1.16.0")
}

flutter {
    source = "../.."
}
