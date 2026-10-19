param(
    [string]$OutputDirectory,
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',
    [string]$BuildDirectory
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $root 'build\xbox-test-build' }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

if (-not $BuildDirectory) {
    $candidate = Join-Path $root "build\xbox-uwp-$($Configuration.ToLower())"
    if (Test-Path -LiteralPath $candidate) {
        $BuildDirectory = $candidate
    } else {
        $BuildDirectory = Join-Path $root 'build\xbox-uwp'
    }
}

$suffix = if ($Configuration -eq 'Debug') { '-Debug' } else { '' }
$package = Join-Path $OutputDirectory "Warthog-UWP-x64$suffix.appx"
& (Join-Path $PSScriptRoot 'package_xbox.ps1') -BuildDirectory $BuildDirectory -OutputPath $package
if ($LASTEXITCODE) { throw 'Package creation failed.' }
& (Join-Path $PSScriptRoot 'sign_xbox.ps1') -PackagePath $package `
    -CertificatePath (Join-Path $OutputDirectory "Warthog-UWP$suffix.cer")
if ($LASTEXITCODE) { throw 'Package signing failed.' }

$dependencySource = Join-Path ${env:ProgramFiles(x86)} `
    'Microsoft SDKs\Windows Kits\10\ExtensionSDKs\Microsoft.VCLibs\14.0\Appx\Retail\x64'
if (Test-Path -LiteralPath $dependencySource) {
    $dependencyOutput = Join-Path $OutputDirectory 'Dependencies\x64'
    New-Item -ItemType Directory -Path $dependencyOutput -Force | Out-Null
    Copy-Item -Path (Join-Path $dependencySource '*.appx') -Destination $dependencyOutput -Force
}

Get-FileHash -Algorithm SHA256 -LiteralPath $package
