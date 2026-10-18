[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d+\.\d+\.\d+-personal\.\d+$')]
    [string]$Version,
    [string]$OutputDirectory,
    [ValidatePattern('^\d+\.\d+\.\d+\.\d+$')]
    [string]$WindowsMetadataVersion
)

$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path $PSScriptRoot -Parent
if (!$OutputDirectory) {
    $OutputDirectory = Join-Path $sourceRoot "artifacts\$Version"
}
$OutputDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)

Push-Location $sourceRoot
try {
    $sourceCommit = git rev-parse HEAD
    if ($LASTEXITCODE) { throw 'Cannot resolve the source commit.' }
    $dirtyFiles = git status --porcelain
    if ($LASTEXITCODE -or $dirtyFiles) { throw 'Commit source changes before building a daily-use version.' }
    if (Test-Path -LiteralPath $OutputDirectory) { throw "Output already exists: $OutputDirectory" }
    if (!$PSCmdlet.ShouldProcess($OutputDirectory, "Test and publish Windows x64 $Version from $sourceCommit")) { return }

    dotnet run --project tests/HASS.Agent.Audio.RegressionTests -c Release
    if ($LASTEXITCODE) { throw 'Audio regression checks failed.' }

    $metadataArgument = @()
    if ($WindowsMetadataVersion) { $metadataArgument = @("-p:CsWinRTWindowsMetadata=$WindowsMetadataVersion") }
    dotnet publish src/HASS.Agent/HASS.Agent/HASS.Agent.csproj -c Release `
        -f net8.0-windows10.0.22621.0 -r win-x64 --no-self-contained `
        -p:Platform=x64 "-p:Version=$Version" "-p:InformationalVersion=$Version+$sourceCommit" `
        -o (Join-Path $OutputDirectory 'client') @metadataArgument
    if ($LASTEXITCODE) { throw 'Client publish failed; output is incomplete.' }

    $clientExe = Join-Path $OutputDirectory 'client/HASS.Agent.exe'
    if (!(Test-Path -LiteralPath $clientExe)) { throw 'Published client executable is missing.' }
    $sdkVersion = dotnet --version
    if ($LASTEXITCODE) { throw 'Cannot resolve the build SDK version.' }
    $manifest = [ordered]@{
        version = $Version
        sourceCommit = $sourceCommit
        upstreamBase = (git merge-base HEAD upstream/main)
        sdk = $sdkVersion
        windowsMetadataOverride = $WindowsMetadataVersion
        runtimeIdentifier = 'win-x64'
        builtAtUtc = [DateTime]::UtcNow.ToString('o')
        clientSha256 = (Get-FileHash -LiteralPath $clientExe -Algorithm SHA256).Hash
        sharedSha256 = (Get-FileHash -LiteralPath (Join-Path $OutputDirectory 'client/HASS.Agent.Shared.dll') -Algorithm SHA256).Hash
    }
    $manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputDirectory 'build.json') -Encoding utf8
    $manifest | ConvertTo-Json
}
finally { Pop-Location }
