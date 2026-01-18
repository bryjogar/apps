# Monorepo Developer Guide

Welcome to the `apps` monorepo. This document serves as the **Source of Truth** for all agents and developers working in this codebase.
**Strict adherence to these rules is mandatory.**

## 1. Project Philosophy (The "North Star")
*   **Privacy First**: NO ads, NO tracking, NO analytics (e.g., No Firebase Analytics, No Crashlytics).
*   **Local First**: All data must be stored locally on the device (Room Database or DataStore). NO external servers for storage. API data collection is acceptable when required, but user data stays on-device.
*   **Minimal Permissions**: Request ONLY the permissions strictly necessary for app features. NO "future-proofing" permissions.
*   **Goal**: Build autonomous, self-contained tools that work without internet connection.

## 2. Monorepo Architecture
*   **Root Context**: The user's specific app lives in a sub-directory (e.g., `budget/`, `ereader/`).
*   **No Git Init**: **DO NOT** initialize a new git repository (`git init`) inside sub-directories. The root is the git repo.
*   **Language**: Kotlin + Jetpack Compose (Material3).

## 3. Known Issues & Troubleshooting
*   **Java 25 Incompatibility**: Android Gradle Plugin 8.2.0 does not support Java 25. The `dev.ps1` script automatically handles this by switching to the embedded Android Studio JBR (Java 21).
*   **Missing Resources**: If `AAPT` complains about missing `mipmap` resources, checks that you are using `@drawable/ic_launcher` and the file exists in `src/main/res/drawable`.
*   **Unresolved References (Compose)**: If `viewModel()` or `ui` references are missing, ensure `lifecycle-viewmodel-compose` is in your dependencies.

## 4. The "Gradle Wrapper" Law (CRITICAL)
*   **Constraint**: You cannot generate binary files (`.jar`).
*   **Action**: You must copy the Gradle engine from the template folder.
    *   Command: `cp -r _templates/* [new-app-folder]/`

## 4. The "CI/CD" Law
Every new app requires a GitHub Action workflow.
**Location**: `.github/workflows/[app-name]-build.yml`
**Template**:

```yaml
name: Build APP_NAME

on:
  push:
    branches: [ "main" ]
    paths:
      - 'APP_NAME/**'

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: gradle

      - name: Grant execute permission for gradlew
        run: chmod +x APP_NAME/gradlew

      - name: Decode Keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > APP_NAME/app/release.jks

      - name: Build with Gradle
        run: cd APP_NAME && ./gradlew assembleRelease
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}

      - name: Rename APK
        run: mv APP_NAME/app/build/outputs/apk/release/app-release.apk APP_NAME/app/build/outputs/apk/release/APP_NAME.apk

      - name: Release APK
        uses: softprops/action-gh-release@v1
        with:
          tag_name: APP_NAME-latest
          name: "APP_NAME (Latest)"
          files: APP_NAME/app/build/outputs/apk/release/APP_NAME.apk
          overwrite: true
```

## 5. The "Signing" Law
`build.gradle.kts` must read secrets from Environment Variables.
**Inject this into `app/build.gradle.kts` inside the `android {}` block:**

```kotlin
signingConfigs {
    create("release") {
        storeFile = file("release.jks")
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

## 6. The "Storefront" Law
Keep the `index.html` app catalog up to date.
*   **Icon Requirement**: Ensure `[app-name]/icon.png` exists.
*   **HTML Snippet**:

```html
<div class="app-card">
    <div class="card">
        <div class="card-header">
            <img src="[app-name]/icon.png" alt="[App Name] Icon" class="app-icon" onerror="this.style.display='none'">
            <div class="card-title-group">
                <h2>[App Name]</h2>
                <span class="status-badge status-new">Fresh Build</span>
            </div>
        </div>
        <p>[Short Description]</p>
        <a href="https://github.com/bryjogar/apps/releases/download/[app-name]-latest/[app-name].apk" class="btn">Download APK</a>
    </div>
</div>
```

## 7. The "Version Lock" Law (CRITICAL)
Jetpack Compose Compiler versions are strictly tied to the Kotlin Gradle Plugin version.
**Required Variations**:
*   **Kotlin Gradle Plugin**: `1.9.22`
*   **Compose Compiler Extension**: `1.5.10`
*   **Android Gradle Plugin (AGP)**: `8.2.0`

**Implementation**:
*   Project-level `build.gradle.kts`: `id("org.jetbrains.kotlin.android") version "1.9.22"`
*   App-level `build.gradle.kts`: `composeOptions { kotlinCompilerExtensionVersion = "1.5.10" }`

## 8. The "Local Dev" Law
*   **Goal**: Enable seamless local verification.
*   **Requirement**: Use the `dev.ps1` script (copied from `_templates/` in Rule #3) for building and verifying apps locally.

## 9. The "Agent Memory" Law
Every app **MUST** have a `README.md` in its root folder containing:
1.  **Mission**: One sentence explaining what the app does.
2.  **Tech Decisions**: Why certain libraries were chosen.
3.  **Manual Tasks**: Things the user must manually verify.
4.  **Agent Context**: Known hacks, unfinished ideas, or constraints for future agents.
