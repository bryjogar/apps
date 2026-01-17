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

4. Automation Compatibility
When scaffolding a new app, assume a GitHub Actions workflow will be created for it.

The workflow will inject the secrets KEYSTORE_PASSWORD, KEY_ALIAS, and KEY_PASSWORD.

```