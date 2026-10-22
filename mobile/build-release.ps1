[CmdletBinding()]
param(
    [string]$ApiBaseUrl,
    [switch]$SmokeTest,
    [switch]$SplitPerAbi,
    [switch]$AppBundle,
    [switch]$AllowDebugSigning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$mobileRoot = $PSScriptRoot
Set-Location $mobileRoot

function Fail([string]$Message) {
    throw "Release build gagal: $Message"
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    if ($SmokeTest) {
        $ApiBaseUrl = 'http://10.0.2.2:3000/api/v1'
    }
    else {
        Fail 'parameter -ApiBaseUrl wajib diisi (contoh: https://api.lifeos.id/api/v1). Gunakan -SmokeTest untuk build emulator.'
    }
}

$apiUri = $null
if (-not [Uri]::TryCreate($ApiBaseUrl, [UriKind]::Absolute, [ref]$apiUri)) {
    Fail "ApiBaseUrl bukan URL absolut yang valid: $ApiBaseUrl"
}

if ($apiUri.Scheme -ne 'https') {
    $localHosts = @('localhost', '127.0.0.1', '10.0.2.2')
    if (-not ($SmokeTest -and $localHosts -contains $apiUri.Host)) {
        Fail 'build distribusi wajib memakai HTTPS. Untuk emulator gunakan -SmokeTest.'
    }
}

$keyProperties = Join-Path $mobileRoot 'android\key.properties'
if (-not $AllowDebugSigning -and -not (Test-Path $keyProperties)) {
    Fail "android\key.properties tidak ditemukan. Siapkan release keystore lebih dulu (lihat RELEASE.md)."
}

$mode = if ($AppBundle) { 'appbundle' } else { 'apk' }
$signingLabel = if ($AllowDebugSigning) { 'debug-signed' } else { 'release-signed' }

Write-Host "Building $mode ($signingLabel) untuk API: $ApiBaseUrl"

$flutterArgs = @(
    'build',
    $mode,
    '--release',
    "--dart-define=API_BASE_URL=$ApiBaseUrl"
)
if ($SplitPerAbi -and -not $AppBundle) {
    $flutterArgs += '--split-per-abi'
}

& flutter @flutterArgs
if ($LASTEXITCODE -ne 0) {
    Fail "flutter build $mode keluar dengan kode $LASTEXITCODE."
}

$versionMatch = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)' | Select-Object -First 1
$version = if ($versionMatch) { $versionMatch.Matches[0].Groups[1].Value } else { '0.0.0' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$label = if ($SmokeTest) { 'smoke' } else { 'release' }
$dist = Join-Path $mobileRoot 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null

if ($AppBundle) {
    $outputs = @(Get-Item 'build\app\outputs\bundle\release\app-release.aab')
}
elseif ($SplitPerAbi) {
    $outputs = @(Get-ChildItem 'build\app\outputs\flutter-apk\app-*-release.apk')
}
else {
    $outputs = @(Get-Item 'build\app\outputs\flutter-apk\app-release.apk')
}

foreach ($file in $outputs) {
    $abiSuffix = ''
    if ($SplitPerAbi) {
        $abi = $file.BaseName -replace '^app-', '' -replace '-release$', ''
        $abiSuffix = "-$abi"
    }

    $target = Join-Path $dist "lifeos-$version-$label-$stamp$abiSuffix$($file.Extension)"
    Copy-Item $file.FullName $target -Force
    $hash = (Get-FileHash -Algorithm SHA256 $target).Hash

    Write-Host "Artifact : $target"
    Write-Host "SHA256   : $hash"
}

Write-Host 'Selesai. Simpan keystore dan android\key.properties di tempat aman (jangan commit).'
