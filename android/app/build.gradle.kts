import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is loaded from android/key.properties, which is gitignored.
// Copy android/key.properties.example and fill in your own upload keystore.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigningFile = keystorePropertiesFile.exists()
if (hasReleaseSigningFile) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
val requiredSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingSigningKeys = requiredSigningKeys.filter {
    keystoreProperties.getProperty(it).isNullOrBlank()
}
val hasReleaseSigning = hasReleaseSigningFile && missingSigningKeys.isEmpty()
val isReleaseTask = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (isReleaseTask && !hasReleaseSigning) {
    // Fail closed: never silently produce a debug-signed release artifact.
    throw GradleException(
        if (!hasReleaseSigningFile) {
            "Release signing is not configured. Copy android/key.properties.example to " +
                "android/key.properties and provide your upload keystore."
        } else {
            "android/key.properties is missing required values: ${missingSigningKeys.joinToString()}"
        },
    )
}

android {
    namespace = "com.mindverse.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.mindverse.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            // When signing is missing, configuration above fails for release tasks.
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
