# Personal HASS.Agent maintenance

This fork follows `hass-agent/HASS.Agent` and produces a local daily-use build. Read
[docs/personal-build.md](docs/personal-build.md) before changing maintenance,
building, updating, or deploying the personal version.

- Keep generally useful fixes on branches based on `upstream/main`, with focused
  commits and regression checks suitable for an upstream PR.
- Keep personal maintenance documentation and build tooling on `personal`.
- Preserve existing command/sensor IDs and runtime configuration during deployment.
  Configuration and credentials belong to the installed app, outside Git.
- Publish source branches and authorized upstream PRs. Build outputs are for local
  use; do not create public binary releases as part of this workflow.
- Track unresolved fork-specific work in `docs/backlog.md`; upstream issues and PRs
  are linked there when applicable.
