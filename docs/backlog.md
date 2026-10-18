# Active work

## Audio device telemetry stops on a lingering session — high priority

Status: in progress. Prerequisite for completing the two microphone automations.

HASS.Agent 2.2.1 calls `Process.GetProcessById` while resolving an unnamed audio
session. A session can outlive its process. The resulting `ArgumentException`
propagates through `GetDeviceSessions` and aborts `GetDevices`, leaving the HA
default-input state stale even though the switch command succeeds in Windows.

Fix the exited-process lookup without dropping healthy device telemetry. Include a
regression check that fails on upstream and passes with the fix, a Release build,
and live HA/Windows state comparison. Preserve the existing automation conditions.
The device-name mismatches in HA and the installed command config have already
been corrected. Closure requires the end-to-end validation above.

## Seated sensor frequently changes state — uninvestigated

Status: observed, outside the client patch. The seated-at-desk sensor repeatedly
changed between on and off during the original diagnostic window. No trigger or
sensor semantics have been changed. Diagnose the raw source and intended behavior
before proposing debounce or other automation changes.
