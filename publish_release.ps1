<#
.SYNOPSIS
    Automated Build & In-App Release Publisher for Keto Planner
.DESCRIPTION
    1. Reads version info or auto-increments patch version.
    2. Builds the Android APK with Gradle.
    3. Copies the built APK to "c:\Users\Casperikz\Desktop\Keto planner\KetoPlanner.apk".
    4. Commits and pushes Git changes to GitHub main.
    5. Creates a GitHub Release (tag vX.Y.Z) via GitHub REST API using saved credentials.
    6. Uploads KetoPlanner.apk to the release asset for in-app updates.
#>
param (
    [string]$Version,
    [string]$Notes = "Performance improvements, UI polish, and updates."
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Keto Planner Auto-Updater & Publisher " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Environment & Paths
$RepoDir = "c:\Users\Casperikz\AndroidStudioProjects\KetoPlanner"
$DesktopApk = "c:\Users\Casperikz\Desktop\Keto planner\KetoPlanner.apk"
$Gradlew = Join-Path $RepoDir "gradlew.bat"
$GitExe = "C:\Program Files\Git\cmd\git.exe"
$BuildGradle = Join-Path $RepoDir "app\build.gradle.kts"

$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"

# 2. Get GitHub Token from Windows Credential Manager
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class CredentialHelper {
    [DllImport("advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);

    [DllImport("advapi32.dll", EntryPoint = "CredFree", SetLastError = true)]
    public static extern void CredFree(IntPtr cred);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public long LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static string GetPassword(string target) {
        IntPtr credPtr;
        if (CredRead(target, 1, 0, out credPtr)) {
            CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            byte[] bytes = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, bytes, 0, cred.CredentialBlobSize);
            CredFree(credPtr);
            return Encoding.UTF8.GetString(bytes);
        }
        return null;
    }
}
"@

$token = [CredentialHelper]::GetPassword("GitHub - https://api.github.com/casperikz")
if (-not $token) {
    Write-Error "Could not read GitHub token from Windows Credential Manager. Please make sure GitHub Desktop is logged in."
    exit 1
}

# 3. Determine Version
$gradleContent = Get-Content $BuildGradle -Raw
$currentCode = 1
$currentName = "1.0.0"

if ($gradleContent -match 'versionCode\s*=\s*(\d+)') {
    $currentCode = [int]$matches[1]
}
if ($gradleContent -match 'versionName\s*=\s*"([^"]+)"') {
    $currentName = $matches[1]
}

if (-not $Version) {
    # Auto-bump patch version: e.g. 1.0.0 -> 1.0.1
    $parts = $currentName.Split('.')
    if ($parts.Count -eq 3) {
        $patch = [int]$parts[2] + 1
        $newVersion = "$($parts[0]).$($parts[1]).$patch"
    } elseif ($parts.Count -eq 2) {
        $newVersion = "$($parts[0]).$($parts[1]).1"
    } else {
        $newVersion = "$currentName.1"
    }
} else {
    $newVersion = $Version.TrimStart('v')
}
$newCode = $currentCode + 1

Write-Host "-> Current Version: v$currentName (code $currentCode)" -ForegroundColor Yellow
Write-Host "-> New Version:     v$newVersion (code $newCode)" -ForegroundColor Green

# 4. Update build.gradle.kts
$gradleContent = $gradleContent -replace 'versionCode\s*=\s*\d+', "versionCode = $newCode"
$gradleContent = $gradleContent -replace 'versionName\s*=\s*"[^"]+"', "versionName = `"$newVersion`""
Set-Content -Path $BuildGradle -Value $gradleContent -NoNewline

# 5. Build APK
Write-Host "-> Building Android APK with Gradle..." -ForegroundColor Cyan
Push-Location $RepoDir
try {
    & $Gradlew assembleDebug
    if ($LASTEXITCODE -ne 0) {
        throw "Gradle build failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

$builtApk = Join-Path $RepoDir "app\build\outputs\apk\debug\app-debug.apk"
if (-not (Test-Path $builtApk)) {
    throw "Built APK not found at $builtApk"
}

# 6. Copy to Desktop output location
Write-Host "-> Copying APK to Desktop: $DesktopApk" -ForegroundColor Cyan
Copy-Item -Path $builtApk -Destination $DesktopApk -Force

# 7. Git Commit & Push
Write-Host "-> Committing and pushing changes to GitHub..." -ForegroundColor Cyan
Push-Location $RepoDir
try {
    & $GitExe add -A
    & $GitExe commit -m "Release v$newVersion: $Notes"
    
    # Push with authenticated remote url
    $remoteAuthUrl = "https://${token}@github.com/casperikz/KetoPlanner.git"
    & $GitExe push $remoteAuthUrl main
} finally {
    Pop-Location
}

# 8. Create GitHub Release
$tagName = "v$newVersion"
Write-Host "-> Creating GitHub Release $tagName..." -ForegroundColor Cyan

$releaseBody = @{
    tag_name = $tagName
    target_commitish = "main"
    name = "Keto Planner $tagName"
    body = $Notes
    draft = $false
    prerelease = $false
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept" = "application/vnd.github.v3+json"
    "User-Agent" = "KetoPlanner-Release-Bot"
}

$releaseResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/casperikz/KetoPlanner/releases" `
    -Method Post `
    -Headers $headers `
    -ContentType "application/json" `
    -Body $releaseBody

$releaseId = $releaseResponse.id
$uploadUrl = $releaseResponse.upload_url -replace '\{\?name,label\}', "?name=KetoPlanner.apk"

Write-Host "-> Uploading KetoPlanner.apk to release assets..." -ForegroundColor Cyan

$curlArgs = @(
    "-s", "-S",
    "-X", "POST",
    "-H", "Authorization: Bearer $token",
    "-H", "Accept: application/vnd.github.v3+json",
    "-H", "Content-Type: application/vnd.android.package-archive",
    "--data-binary", "@$DesktopApk",
    $uploadUrl
)
$curlOutput = & curl.exe @curlArgs
$assetResponse = $null
try {
    $assetResponse = $curlOutput | ConvertFrom-Json
} catch {}

$downloadUrl = if ($assetResponse -and $assetResponse.browser_download_url) { $assetResponse.browser_download_url } else { "https://github.com/casperikz/KetoPlanner/releases/download/$tagName/KetoPlanner.apk" }

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " SUCCESS! Release $tagName is now LIVE on GitHub!" -ForegroundColor Green
Write-Host " Download URL: $downloadUrl" -ForegroundColor Green
Write-Host " Open Keto Planner on your phone to see the update prompt!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
