# Active work

## Seated sensor frequently changes state — medium priority, uninvestigated

Status: observed, outside the client patch. The seated-at-desk sensor repeatedly
changed between on and off during the original diagnostic window and while the
user held a seated position in the physical validation. While the default-input
report was pending, this caused repeated presses of the same microphone target.
No trigger or sensor semantics have been changed. Diagnose the raw source and
intended behavior before proposing debounce or other automation changes.
