---
trigger: always_on
---

# Antigravity Workspace Rules for bryangarrison/apps

## 1. Monorepo Structure
- We are in a **Monorepo**. The root contains the website (`index.html`).
- Each application lives in its own **isolated sub-directory** (e.g., `ereader/`, `verify/`).
- **DO NOT** create a new git repository inside sub-directories.

## 2. Android Architecture Standards
- **Language:** Kotlin + Jetpack Compose (Material3).
- **Build System:** Gradle (Kotlin DSL).
- **Target:** MinSDK 26, TargetSDK 34+.

## 3. CI/CD & Signing (CRITICAL)
- **NEVER** hardcode keystore passwords in `build.gradle.kts`.
- **ALWAYS** configure the `release` signing config to read from Environment Variables.
- **ALWAYS** use this exact signing block in `app/build.gradle.kts`:

```kotlin
signingConfigs {
    create("release") {
        storeFile = file("../../certs/release.jks") // Shared Keystore in root
        storePassword = System.getenv("KEYSTORE_PASSWORD")
        keyAlias = System.getenv("KEY_ALIAS")
        keyPassword = System.getenv("KEY_PASSWORD")
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
```

## 4. Automation Compatibility
When scaffolding a new app, assume a GitHub Actions workflow will be created for it.

The workflow will inject the secrets KEYSTORE_PASSWORD, KEY_ALIAS, and KEY_PASSWORD.

## 5. New App Scaffolding Standards
When creating a new Android application module:

1.  **AndroidX Support**: ALWAYS create a `gradle.properties` file in the module root containing:
    ```properties
    android.useAndroidX=true
    ```
2.  **Standard Resources**: ALWAYS create the following standard resource files in `app/src/main/res/` to prevent build errors:
    - `values/themes.xml` (Define `Theme.<AppName>`)
    - `mipmap-anydpi-v26/ic_launcher.xml` & `ic_launcher_round.xml`
    - `drawable/ic_launcher_background.xml` & `ic_launcher_foreground.xml`
    - `xml/data_extraction_rules.xml` & `xml/backup_rules.xml` (Referenced in standard manifests)
3.  **Gradle Wrapper**: ALWAYS ensure the Gradle Wrapper (`gradlew`, `gradlew.bat`, `gradle/wrapper/`) is properly initialized in the module directory.
    - **Recommended**: Copy these files from the repository root (if available) or another working module to ensure version consistency.