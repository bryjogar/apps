# Set context to script directory to fix relative path issues
Set-Location $PSScriptRoot

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
    Write-Host "Creating local.properties..."
    # Safe path replacement for Windows
    $safeSdk = $androidSdk -replace "\\", "/"
    "sdk.dir=$safeSdk" | Out-File "local.properties" -Encoding ASCII
}

# 1. Self-Heal Gradle
if (-not (Test-Path "gradlew")) {
    Write-Host "Injecting Gradle Engine..."
    # .. refers to parent of current script directory now
    if (Test-Path "../_templates") {
        Copy-Item -Recurse -Force "../_templates/*" .
    } else {
        Write-Warning "Templates folder not found at ../_templates. Skipping self-heal."
    }
}

# 2. Launch Emulator Safely
$deviceState = adb get-state 2>$null
if ($deviceState -ne "device") {
    # Check if emulator process is already running to avoid fork bombing/freezing
    $runningEmulators = Get-Process "emulator*" -ErrorAction SilentlyContinue
    if ($runningEmulators) {
        Write-Host "Emulator process detected but not ready (State: $deviceState). Waiting..."
    } else {
        Write-Host "Starting Emulator..."
        $avd = (emulator -list-avds | Select-Object -First 1)
        if ($avd) {
            Write-Host "Booting AVD: $avd"
            # Start emulator in background
            Start-Process emulator -ArgumentList "@$avd" -NoNewWindow
        } else {
            Write-Error "No AVDs found. Please create one in Android Studio first."
            exit 1
        }
    }

    # Wait for device loop (Max 60 seconds)
    Write-Host "Waiting for device to become ready (Timeout 60s)..."
    $counter = 0
    while ($counter -lt 60) {
        $state = adb get-state 2>$null
        if ($state -eq "device") {
            Write-Host "Device Ready!"
            break
        }
        Start-Sleep -Seconds 1
        $counter++
        Write-Host -NoNewline "."
    }
    
    if ($counter -ge 60) {
        Write-Error "Timeout waiting for emulator. Aborting to prevent freeze."
        exit 1
    }
}

# 3. Build & Install
Write-Host "`nBuilding and Installing..."

# Prepare Environment Hash for Start-Process to ensure JAVA_HOME is sticky
$processEnv = @{
    "JAVA_HOME" = $env:JAVA_HOME
    "PATH" = $env:PATH
    "ANDROID_HOME" = $androidSdk
}

if (Test-Path ".\gradlew.bat") {
    # Use Invoke-Process logic or just Start-Process with Environment
    # Note: PowerShell Core 7+ supports -Environment. Windows PowerShell 5.1 (default) does NOT.
    # We must check version or fallback to just relying on current env + strict invocation.
    
    # Since user is likely on Win10/11 default PS 5.1, we rely on current process env injection.
    # We already set $env:JAVA_HOME above.
    
    # Check java version in current shell to be sure
    Write-Host "Checking Java version for build..."
    & java -version

    # Run directly in this shell to ensure env inheritance
    & .\gradlew.bat installDebug
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build Failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
} else {
    Write-Error "gradlew.bat not found in $PWD"
    exit 1
}

# 4. Force Launch App
# We look for applicationId = "..."
$package = Select-String -Path "app/build.gradle.kts" -Pattern 'applicationId\s*=\s*"(.*)"' | ForEach-Object { $_.Matches.Groups[1].Value }

if ($package) {
    Write-Host "Launching $package..."
    adb shell monkey -p $package -c android.intent.category.LAUNCHER 1
} else {
    Write-Error "Could not determine package name from build.gradle.kts"
}
