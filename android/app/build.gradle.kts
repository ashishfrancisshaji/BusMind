plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smart_bus_companion"
    compileSdk = 36
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    
    kotlinOptions {
        jvmTarget = "1.8"
    }
    
    defaultConfig {
        applicationId = "com.example.smart_bus_companion"
        minSdk = flutter.minSdkVersion  // Changed from flutter.minSdkVersion for compatibility
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        
        // Add this for TFLite compatibility
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    // Add this to avoid conflicts
    packagingOptions {
        resources.excludes.add("META-INF/DEPENDENCIES")
    }
}

dependencies {
    // UPDATED: Use compatible TensorFlow Lite version
    implementation("org.tensorflow:tensorflow-lite:2.13.0")  // Changed from 2.14.0
    implementation("org.tensorflow:tensorflow-lite-support:0.4.3")  // Changed from 0.4.4
    
    implementation("androidx.core:core:1.13.1")
    implementation("androidx.core:core-ktx:1.13.1")
}
