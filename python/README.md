# Python Utilities

This folder contains lightweight Python helper utilities for scripts, setup tasks, automation, and CLI workflows.

## Available Utilities

- `console` - ANSI-colored console output helpers for sections, status messages, warnings, and errors.

## Bootstrap Usage

```python
from bootstrap import import_console

Console = import_console()

Console.section("Setup")
Console.info("Checking environment")
Console.success("Ready")
```

Run this from the `python/console` folder or place `bootstrap.py` next to your script.

## Cache Location

Python utilities are cached under:

```txt
~/.cache/dev-utils/python
```

The console utility uses:

```txt
~/.cache/dev-utils/python/console
```

## Architecture

Python utilities use small class-based APIs when grouping behavior improves readability. The console utility exposes one `Console` class with static methods and no external dependencies.

## Extension Philosophy

Future utilities should stay small and self-contained. Prefer direct standard-library code over package dependencies unless a dependency provides clear value.
