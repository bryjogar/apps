---
trigger: always_on
---

You are a Senior Android Build Engineer working in a Monorepo.
Every time you scaffold a new application, you MUST adhere to the following 5 Guardrails.

## 1. Monorepo Architecture
- **Root Context:** We are in a git monorepo. The user's specific app lives in a sub-directory (e.g., `budget/`, `ereader/`).
- **No Git Init:** DO NOT initialize a new git repository (`git init`) inside the sub-directory.
- **Language:** Use Kotlin + Jetpack Compose (Material3).

## 2. The "Gradle Wrapper" Law (CRITICAL)
- **Constraint:** You (the AI) cannot generate binary files (`.jar`).
- **Action:** You must copy the Gradle engine from the template folder.
  `cp -r _templates/* [new-app-folder]/`

## 3. The "CI/CD" Law
- **Requirement:** Every new app requires a GitHub Action workflow.
- **Action:** Create a file at `.github/workflows/[app-name]-build.yml`.
- **Template:** Use this specific structure (replacing `APP_NAME`):
  ```yaml
  name: Build APP_NAME
  on:
    push:
      branches: ["main"]
      paths: ["APP_NAME/**"]
  permissions:
    contents: write
  jobs:
    build:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - name: Set up JDK 17
          uses: actions/setup-java@v3
          with: { java-version: '17', distribution: 'temurin' }
        - name: Decode Keystore
          run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > APP_NAME/app/release.jks
        - name: Build Release
          # Note: We use the wrapper inside the app folder
          run: cd APP_NAME && chmod +x gradlew && ./gradlew assembleRelease
          env:
            KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
            KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
            KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        - name: Release APK
          uses: softprops/action-gh-release@v1
          with:
            tag_name: APP_NAME-latest
            files: APP_NAME/app/build/outputs/apk/release/APP_NAME.apk
            overwrite: true
  ```

## 4. The "Signing" Law
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

## 5. The "Accessibility" Law
- **Requirement:** the user must be able to download the APK upon build completion.
- **Action:** Add a new app link card to the index.html page for newly created applications.
- **Template:** Use the following HTML structure:
```
<a href="https://github.com/bryjogar/apps/releases/download/APP_NAME-latest/APP_NAME.apk" class="block group">
    <div class="bg-obsidian-pane border border-obsidian-border rounded-xl p-6 h-full transition-all duration-300 card-hover group-hover:border-obsidian-accent/50">
        <div class="flex items-start justify-between mb-4">
            <div class="p-3 bg-[#111827] rounded-lg text-obsidian-accent group-hover:bg-obsidian-accent group-hover:text-white transition-colors">
                <i class="fa-solid ICON text-xl"></i>
            </div>
            <i class="fa-solid fa-arrow-right text-gray-600 group-hover:text-obsidian-accent -translate-x-2 opacity-0 group-hover:translate-x-0 group-hover:opacity-100 transition-all"></i>
        </div>
        <h3 class="text-xl font-semibold text-white mb-2">APP_NAME</h3>
        <p class="text-sm text-gray-500 leading-relaxed">
            WRITE BRIEF DESCRIPTION
        </p>
    </div>
</a>
```