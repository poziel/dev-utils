# Python Console Utility

The Python console utility provides a small ANSI-colored output API for scripts and CLI helpers.

## API

```python
Console.section(message)
Console.info(message)
Console.success(message)
Console.warning(message)
Console.error(message)
```

## Usage

```python
from bootstrap import import_console

Console = import_console()

Console.section("Install")
Console.info("Downloading files")
Console.success("Install complete")
Console.warning("Optional setting was skipped")
Console.error("Something failed")
```

## Bootstrap Behavior

`bootstrap.py` exposes a single public function:

```python
from bootstrap import import_console
```

When called, it:

1. Creates `~/.cache/dev-utils/python/console`.
2. Downloads the remote `version.txt`.
3. Compares it with the cached `version.txt`.
4. Downloads `console.py` and `version.txt` when the version changed.
5. Imports the cached `console.py`.
6. Reuses the cached file if the network is unavailable.

## Cache Invalidation

The cache updates when the remote `version.txt` differs from the cached version. This simple version file avoids package metadata and keeps the bootstrap easy to inspect.

## Implementation Philosophy

The utility is a single Python file, depends only on the standard library, and uses ANSI escape codes directly.
