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

Build commands and the verification evidence are added when exercised.
