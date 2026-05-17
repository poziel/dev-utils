# dev-utils

`dev-utils` is a lightweight collection of reusable developer utilities for scripts, automation, CLI helpers, setup tasks, homelab tooling, and day-to-day workflow glue.

This repository is intentionally not a framework. It exists to keep small, practical helpers in one place while making them easy to reuse from different languages.

## Philosophy

- Keep utilities dependency-free whenever possible.
- Prefer plain functions and simple classes over large abstractions.
- Make each utility readable enough to copy, audit, and modify.
- Keep bootstrap logic small and predictable.
- Keep remote loading simple and predictable.
- Make it easy to add new languages without changing existing ones.

## Supported Languages

- PowerShell 5+
- Python 3.9+
- JavaScript on Node.js 18+

Each language has its own folder, README, bootstrap script, and utility implementation files.

## Bootstrap System

Every language includes a small bootstrap layer. The PowerShell bootstrap is web-first: it downloads the requested plugin bootstrap from GitHub raw URLs and imports that plugin into the current session.

The placeholder base URL is:

```txt
https://raw.githubusercontent.com/poziel/dev-utils/main/
```

The PowerShell bootstrap flow is intentionally simple:

1. Fetch `powershell/bootstrap.ps1`.
2. Pass `-Imports` with one or more utility names.
3. Resolve each utility name to a plugin folder.
4. Download that plugin's `bootstrap.ps1` from GitHub raw.
5. Let the plugin bootstrap load its own files.
6. Dot-source the loaded functions into the current session.

Python and JavaScript still have starter bootstrap files. Their final import strategy should follow the same simple one-bootstrap-per-language direction as the repository evolves.

## Cache Policy

PowerShell does not use a persistent cache. It loads the latest requested utility from GitHub raw each time. This keeps the behavior easy to reason about and avoids local version management.

## Project Goals

This project should stay:

- lightweight
- modular
- dependency-free by default
- beginner-friendly
- production-quality
- easy to extend
- easy to inspect

## Repository Structure

```txt
dev-utils/
  powershell/
    README.md
    console/
      README.md
      bootstrap.ps1
      messages.ps1
      banner.ps1
      prompts.ps1
    environment/
      README.md
      bootstrap.ps1
      variables.ps1
      drives.ps1
      paths.ps1
  python/
    README.md
    console/
      README.md
      bootstrap.py
      console.py
      version.txt
  javascript/
    README.md
    console/
      README.md
      bootstrap.js
      console.js
      version.txt
```

## Future Extensibility

New utilities should follow the same pattern:

- one plugin folder
- one plugin `bootstrap.ps1`
- a small number of focused implementation files
- one focused README

New languages can be added by creating another top-level language folder with the same conventions.
