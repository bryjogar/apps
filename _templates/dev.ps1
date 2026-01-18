# 0. Ensure Android Tools and Java are in PATH
$androidSdk = "$env:LOCALAPPDATA\Android\Sdk"
$pathsToAdd = @(
    "$androidSdk\platform-tools",
    "$androidSdk\emulator",
    "$androidSdk\cmdline-tools\latest\bin"
)

# Force JBR (Java 21) if available, to avoid Java 25 issues
$jbrPath = "C:\Program Files\Android\Android Studio\jbr"
if (Test-Path $jbrPath) {
    Write-Host "Using Embedded JBR from Android Studio..."
    $env:JAVA_HOME = $jbrPath
    $env:PATH = "$jbrPath\bin;$env:PATH"
}

foreach ($p in $pathsToAdd) {
    if (Test-Path $p) {
        if ($env:PATH -notlike "*$p*") {
            Write-Host "Adding $p to PATH..."
            $env:PATH = "$p;$env:PATH"
        }
    }
}

# 0.1 Ensure local.properties exists (Critical for Gradle)
if (-not (Test-Path "local.properties")) {
    Write-Host "🔧 Creating local.properties..."
    # Escape path for properties file (C:\ -> C\:\\)
    $escapedSdk = $androidSdk -replace "\\", "\\" -replace ":", "\:"
    "sdk.dir=$escapedSdk" | Out-File "local.properties" -Encoding ASCII
}

# 1. Self-Heal Gradle
if (-not (Test-Path "gradlew")) {
    Write-Host "Injecting Gradle Engine..."
    Copy-Item -Recurse -Force "../_templates/*" .
}

# 2. Launch Emulator if needed
$deviceState = adb get-state 2>$null
if ($deviceState -ne "device") {
    Write-Host "Starting Emulator..."
    $avd = (emulator -list-avds | Select-Object -First 1)
    if ($avd) {
        # Start emulator in background
        Start-Process emulator -ArgumentList "@$avd" -NoNewWindow
        # Wait for it to boot (Simple wait, can be improved)
        Write-Host "Waiting for emulator to boot..."
        adb wait-for-device
    } else {
        Write-Error "No AVDs found. Create one in Android Studio."
        exit 1
    }
}

# 3. Build & Install
Write-Host "Building and Installing..."
./gradlew installDebug

# 4. Force Launch App
$package = Select-String -Path "app/build.gradle.kts" -Pattern 'applicationId = "(.*)"' | ForEach-Object { $_.Matches.Groups[1].Value }
if ($package) {
    Write-Host "Launching $package..."
    adb shell monkey -p $package -c android.intent.category.LAUNCHER 1
} else {
    Write-Error "Could not determine package name from build.gradle.kts"
}
