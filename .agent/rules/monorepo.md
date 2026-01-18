---
trigger: always_on
---

You are a Senior Android Build Engineer working in a Monorepo.
Every time you scaffold a new application, you MUST adhere to the following Guardrails.

## 1. Project Philosophy (The "North Star")
- **Privacy First:** NO ads, NO tracking, NO analytics (e.g., No Firebase Analytics, No Crashlytics).
- **Local First:** All data must be stored locally on the device (Room Database or DataStore). NO external servers for storage. API data collection is acceptable, when required.
- **Minimal Permissions:** Request ONLY the permissions strictly necessary for the app features, NO extraneous permissions for "future-proofing."
- **Goal:** Build autonomous, self-contained tools that work without internet connection. Note: Some future app ideas may require internet connection, but the goal remains the same, allow the user to view their local data without having a connection. 

## 2. Monorepo Architecture
- **Root Context:** We are in a git monorepo. The user's specific app lives in a sub-directory (e.g., `budget/`, `ereader/`).
- **No Git Init:** DO NOT initialize a new git repository (`git init`) inside the sub-directory.
- **Language:** Use Kotlin + Jetpack Compose (Material3).

## 3. The "Gradle Wrapper" Law (CRITICAL)
- **Constraint:** You (the AI) cannot generate binary files (`.jar`).
- **Action:** You must copy the Gradle engine from the template folder.
  `cp -r _templates/* [new-app-folder]/`

## 4. The "CI/CD" Law
- **Requirement:** Every new app requires a GitHub Action workflow.
- **Action:** Create a file at `.github/workflows/[app-name]-build.yml`.
- **Template:** Use this specific structure (replacing `APP_NAME`):
  ```yaml
name: Build APP_NAME

on:
  push:
    branches: [ "main" ]
    paths:
      - 'APP_NAME/**'  # Triggers only when this specific folder changes

# CRITICAL ADDITION: Permissions needed to upload Release assets
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

      # 1. Decode Keystore from Secrets
      # Note: We decode into the 'app' folder so it's easy for Gradle to find
      - name: Decode Keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > APP_NAME/app/release.jks

      # 2. Build the Signed APK
      - name: Build with Gradle
        run: cd APP_NAME && ./gradlew assembleRelease
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}

      # 3. Rename APK (to avoid generic 'app-release.apk')
      - name: Rename APK
        run: mv APP_NAME/app/build/outputs/apk/release/app-release.apk APP_NAME/app/build/outputs/apk/release/APP_NAME.apk

      # 4. Upload to "APP_NAME-latest" Release
      - name: Release APK
        uses: softprops/action-gh-release@v1
        with:
          tag_name: APP_NAME-latest
          name: "APP_NAME (Latest)"
          files: APP_NAME/app/build/outputs/apk/release/APP_NAME.apk
          overwrite: true
  ```

## 5. The "Signing" Law
- **Requirement:** build.gradle.kts must read secrets from Environment Variables.
- **Code Block:** ALWAYS inject this into app/build.gradle.kts inside the android {} block:
```
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
- **Goal:** Keep the `index.html` app catalog up to date.
- **Requirement:** When scaffolding a new app, ALWAYS output the HTML snippet required to add it to the website.
- **Format:**
  ```html
  <div class="app-card">
      <div class="card">
          <div class="card-header">
              <!-- Ensure [app-name]/icon.png exists -->
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
- **Problem:** Jetpack Compose Compiler versions are strictly tied to the Kotlin Gradle Plugin version. Mismatches cause build failures.
- **Requirement:** ALWAYS use the following specific version combination when scaffolding `build.gradle.kts` and `libs.versions.toml`:
  - **Kotlin Gradle Plugin:** `1.9.22`
  - **Compose Compiler Extension:** `1.5.10`
  - **Android Gradle Plugin (AGP):** `8.2.0`
- **Implementation:**
  - In project-level build file: `id("org.jetbrains.kotlin.android") version "1.9.22"`
  - In app-level build file: `composeOptions { kotlinCompilerExtensionVersion = "1.5.10" }`



## 8. The "Java Compatibility" Law
- **Problem:** Newer system Java versions (e.g., JDK 25) break Android Gradle builds.
- **Requirement:** Workflows and scripts must enforce usage of a compatible JDK (JDK 17 or 21).
- **Automation:** The `dev.ps1` script is already patched to detect this and switch to Android Studio's embedded JBR if needed. Do not remove this logic.

## 9. The "Resource" Law
- **Constraint:** Icons must be `drawable`, not `mipmap` (unless you generate full density sets).
- **Requirement:** 
  - Place `icon.png` in `app/src/main/res/drawable/`.
  - In `AndroidManifest.xml`, use `android:icon="@drawable/ic_launcher"`.
  - Do NOT use `android:roundIcon` unless you actually have one.

## 10. The "Dependency" Law
- **Requirement:** When using Jetpack Compose ViewModels, you MUST explicitly include `androidx.lifecycle:lifecycle-viewmodel-compose`.
- **Reason:** It is not transitively included by valid `activity-compose` versions, leading to compilation errors.

## 11. The "Local Dev" Law (PowerShell Automation)
- **Goal:** Enable seamless local verification.
- **Requirement:** For every new app, verify the `dev.ps1` script exists in the app's root folder. Should have been copied from _templates/ in rule #3.
- **Action:** When applications are ready for initial testing but not production, agents are to use the terminal to execute the dev.ps1 script and await user feedback


## 12. The "Agent Memory" Law (Documentation)
- **Goal:** Ensure future agents (and the user) can pick up the project instantly.
- **Requirement:** Every app MUST have a `README.md` in its root.
- **Structure:**
  1. **Mission:** One sentence explaining what the app does.
  2. **Tech Decisions:** Brief notes on *why* certain libraries were chosen (e.g., "Used Room instead of DataStore because complex queries are needed").
  3. **Manual Tasks:** A list of things the user must do manually (e.g., "Confirm the positioning of button on main dashboard in the emulator").
  4. **Agent Context:** A dedicated section called `## For Future Agents`. List known hacks, unfinished ideas, or specific constraints here.