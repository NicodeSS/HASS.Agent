# Personal daily-use build

## Agreed maintenance model

The source checkout is `D:\Project\HASS.Agent`. The GitHub fork is
<https://github.com/NicodeSS/HASS.Agent> (`origin`); the upstream is
<https://github.com/hass-agent/HASS.Agent> (`upstream`). `main` follows upstream;
`personal` integrates upstream changes with independently committed local fixes.
The existing upstream README remains the product introduction.

Fetch upstream and inspect changes before merging `upstream/main` into `personal`.
Individual fixes may be cherry-picked when a whole upstream update is not wanted.
General fixes use a separate branch from `upstream/main` for upstream PRs. Merge the
same fix into `personal`; keep personal build changes out of the upstream PR.
When upstream includes a local fix, reconcile it during the next merge rather than
maintaining a duplicate implementation.

Build Windows x64 Release artifacts locally using the upstream .NET 8 target.
Record the source commit and personal version in each output. Public source and
upstream contributions are allowed; binary releases remain local-only.

## Runtime and deployment

The installed client remains the daily-use entry point. Source build directories
are not runtime data directories. Before replacing the client, retain an exact
backup of the installed binaries and configuration, preserving command and sensor
IDs, MQTT identity, and settings. Secrets stay outside the checkout and archives
intended for sharing. Deploy only after tests, build, and scope review succeed.
Keep the existing Satellite Service unless the fix or compatibility requires it.

The official updater points to upstream GitHub releases. Disable update checks on
the personal installation so an official installer does not replace personal
patches. Source updates continue through fetch, merge, local build, and validation.
Rollback restores the saved binaries and, if a migration occurred, matching config.

## Initial acceptance

- An exited process with a lingering Windows audio session does not abort device
  enumeration or leave the default-input sensor stale.
- Real microphone switches are reflected by both Windows and Home Assistant.
- Both microphone automations retain their conditions and switch in both directions.
- Existing MQTT entities and configured commands survive deployment.

## Build and update commands

Prerequisites: PowerShell, Git, a .NET SDK capable of targeting .NET 8, the .NET 8
Windows Desktop runtime, and a Windows SDK supplying CsWinRT metadata. The upstream
default requests SDK 10.0.22621. On this host use the installed SDK 10.0.26100.0,
passed explicitly as
`-WindowsMetadataVersion 10.0.26100.0`. This changes the CsWinRT metadata source;
the project's .NET 8 / Windows 10.0.22621 target remains unchanged. Without this
argument the upstream metadata selection is preserved. The WinGet SDK installation
is local state, outside the shared dotfiles Windows installer.

From a clean committed checkout on `personal`:

```powershell
git fetch upstream
git log --oneline HEAD..upstream/main
git merge upstream/main
dotnet run --project tests/HASS.Agent.Audio.RegressionTests
.\scripts\Build-Personal.ps1 -Version 2.2.1-personal.1 -WindowsMetadataVersion 10.0.26100.0 -WhatIf
.\scripts\Build-Personal.ps1 -Version 2.2.1-personal.1 -WindowsMetadataVersion 10.0.26100.0
```

Choose the version for the current upstream base and increment the personal suffix.
The script checks clean source, runs the audio regression, and publishes the x64
client into ignored `artifacts/<version>/client`, with commit, SDK and binary hashes
in `build.json`. It refuses to overwrite an existing output. A failed publish leaves
an incomplete output for diagnosis; use a new output directory after resolving it.
The script builds the client and its shared assembly. It does not deploy, change
runtime configuration, update the Satellite Service, or publish GitHub releases.

Copy the validated client output into the stopped installed client directory,
preserving its `config`, `logs`, and `cache` directories. Before deployment, verify
that the build output contains none of those runtime directories. Keep an exact
binary backup outside the installation; protect any configuration backup with
Windows DPAPI under the current user, since app settings can contain credentials.
Then start the existing executable path, verify its product version and MQTT
connection, and compare Windows default-input state with HA while running both
automations with `skip_condition: false`. Manual triggering verifies conditions and
actions; physical bed/seat transitions require a separate user acceptance check.
