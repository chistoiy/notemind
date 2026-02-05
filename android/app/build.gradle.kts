plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.notemind.notes"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // 应用ID
        applicationId = "com.notemind.notes"
        // 版本配置
        minSdk = flutter.minSdkVersion
        targetSdk = 34 // 适配Android 14
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 禁止横屏
        vectorDrawables.useSupportLibrary = true
        

    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // 启用代码混淆和压缩
            isMinifyEnabled = true
            isShrinkResources = true
            
            // 配置混淆规则
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    // 按架构拆分APK减小体积
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a")
            isUniversalApk = true // 生成通用APK和架构特定APK
        }
    }
}

flutter {
    source = "../.."
}
