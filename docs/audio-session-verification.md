# Audio session recovery validation (2026-10-18)

This is a dated verification record. Current unresolved work is maintained only in
[backlog.md](backlog.md); the maintenance entry point is
[personal-build.md](personal-build.md).

## Source and build

- Upstream base: `bb97a9f365950c7dadd6fa4c4ebf1b61e8901667` (2.2.1).
- General fix: `f4e779c4eceb57e6da2e640a7fb3b1bfc19fedc2`, submitted as
  [upstream PR #507](https://github.com/hass-agent/HASS.Agent/pull/507).
- Deployed build source: `1af8acdbd384f968cea36ef6752a6992a80c05bd`.
- Product version: `2.2.1-personal.1`, including the source hash in the informational
  version. Target framework remains `net8.0-windows10.0.22621.0`, Windows x64.
- Build SDK: .NET SDK 10.0.101. CsWinRT metadata explicitly selected from installed
  Windows SDK 10.0.26100.0. Full `Build-Personal.ps1` execution exited 0.

The console regression failed on the original resolver with a real exited-process
PID and passed all five checks with the fix: empty and nonempty fallback names,
live process naming, cached naming, and a session without an owning process.

## Deployment and runtime checks

The publish output contained 440 files (160,230,168 bytes), with no runtime config,
cache or log directories. All copied binary hashes matched the publish output.
Original binaries were backed up before replacement. All seven configuration files
were archived in memory and protected with Windows DPAPI CurrentUser; decrypting
the backup reproduced the original archive hash. The six non-app-settings config
files remained byte-identical after startup, preserving command and sensor IDs.

The existing client path was retained and the Satellite Service was unchanged.
`CheckForUpdates` was changed from true to false; the already-false
`EnableExecuteUpdateInstaller` was preserved. Startup reported the personal product
version, initialized audio, loaded the existing commands and sensors, and connected
to MQTT. Audio device telemetry again included nine input and nine output devices.

Both existing microphone automations were manually run with
`skip_condition: false`. The desk automation selected Optimized, and the bed
automation selected Alternative. Windows default input and HA default-input state
agreed in both directions; both traces finished with their original conditions
passing. HA convergence in this run was approximately 2 and 21 seconds. An initial
15-second probe was shorter than the configured 20-second sensor update interval;
the acceptance window was corrected to 45 seconds without changing the sensor.

## Physical trigger verification

The user performed real seated, standing and in-bed transitions while a read-only
event recorder captured the sensor changes, automation events and input state.
Both latest execution traces identified the corresponding state trigger, finished
their actions, and showed both original conditions passing:

- Seated-at-desk trigger: completed; Windows and HA selected Optimized.
- Bed-occupied trigger at 13:46:04 local time: completed; HA selected Alternative
  at 13:46:23, and direct Windows default-input readback agreed.

The recorded bed event and microphone update preceded the user leaving the bed to
click confirmation. UI confirmation was not treated as a requirement to remain in
the measured position. Audio errors were absent after the personal client started;
direct inspection still found 25 audio sessions whose owning processes had exited.
The live check therefore retained the original failure condition.

The seated sensor repeatedly toggled during the first physical test, causing
repeated presses of the same target while the 20-second input report was pending.
The user subsequently confirmed these transitions are normal. They are not a
sensor defect. The original client acceptance did not change sensor semantics.

## Automation follow-up

The approved HA behavior for this single-occupant room is to switch only when
one position reports occupied and the other explicitly reports clear. If both
positions report occupied, or both report clear, retain the selected input.
Only switch between the two managed microphone inputs; preserve manually selected
other inputs and reject unknown/unavailable reports. No sensor debounce is added.

Each of the two existing automations checks its own occupied position, the other
clear position, and the exact opposite input. Re-evaluate on all three relevant
changes: own position becomes occupied, the other clears, or input telemetry
reports the opposite microphone. This allows a previously blocked location
transition to be reconsidered when overlapping occupancy resolves, or when an
earlier command's delayed input report arrives. Actions and automation IDs remain
unchanged. Repeated same-target commands before telemetry updates are still
possible; this follow-up does not claim to suppress them.

Both updated configurations were saved through the HA configuration API, read
back exactly, and remained enabled. Thirty-three checks passed on the actual HA
automation engine using isolated occupancy/input entities and event-only actions:
all four occupancy combinations against both managed inputs, a manual input and
unknown/unavailable; all six trigger paths; overlapping occupancy resolution;
and delayed input acknowledgements after changing position in both directions.
The exact temporary automations and entities were removed and absence verified.

The live desk check selected Alternative first, then the updated automation
restored Optimized using real sensor conditions. HA and direct Windows readback
agreed. The updated bed path was covered by the isolated engine tests; the
earlier physical bed acceptance above predates this automation follow-up and was
not repeated. The client binary and sensor configuration were unchanged.

## Rollback

For this deployment, the local receipt records the original binary hashes, new file
paths, and backup directory. Stop only the exact installed client process. Restore
the saved binaries to their corresponding relative paths and remove only new files
listed in that receipt, after checking each resolved path stays inside the installed
client directory. Decrypt `config.zip.dpapi` under the same Windows user and restore
the configuration when reverting its settings or a format migration. Restart the
existing client executable and recheck MQTT and default-input reporting. Do not use
an unrelated machine's DPAPI context or put decrypted credentials in the repository.
