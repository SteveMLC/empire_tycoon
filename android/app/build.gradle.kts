plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add Google Services plugin
    id("com.google.gms.google-services")
}

import java.util.Properties
import java.io.FileInputStream

// Load key.properties file
val keystorePropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.go7studio.empire_tycoon"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    // Configure signing
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.go7studio.empire_tycoon"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        
        // ADMOB FIX: Set minSdk to 23 to satisfy Google Mobile Ads SDK requirements
        // Previous: minSdk = flutter.minSdkVersion (was 21)
        // Google Mobile Ads SDK requires API 23 minimum
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use the release signing configuration
            signingConfig = signingConfigs.getByName("release")
            
            // Configure shrinking
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Workaround: Use SYMBOL_TABLE to avoid "failed to strip debug symbols" on Windows
            // (Flutter 3.32+ regression with "full" / strip step; SYMBOL_TABLE path is reliable)
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
            
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

// Add Google Mobile Ads dependency for AdMob integration
dependencies {
    implementation("com.google.android.gms:play-services-ads:24.2.0")
    // Google Play Games Services v2 SDK - REQUIRED for Google Play Console recognition
    implementation("com.google.android.gms:play-services-games-v2:+")
    // Note: games_services plugin provides Flutter bindings, but native v2 SDK is required for Play Console
    
    // Add core library desugaring for flutter_local_notifications compatibility
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
