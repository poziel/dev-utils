# JavaScript Console Utility

The JavaScript console utility provides a small ANSI-colored output API for Node.js scripts and CLI helpers.

## API

```javascript
Console.section(message)
Console.info(message)
Console.success(message)
Console.warning(message)
Console.error(message)
```

## Usage

```javascript
const Console = require('./bootstrap')

Console.section('Install')
Console.info('Downloading files')
Console.success('Install complete')
Console.warning('Optional setting was skipped')
Console.error('Something failed')
```

## Bootstrap Behavior

`bootstrap.js` exports the cached `Console` class:

```javascript
const Console = require('./bootstrap')
```

When required, it:

1. Creates `~/.cache/dev-utils/javascript/console`.
2. Downloads the remote `version.txt`.
3. Compares it with the cached `version.txt`.
4. Downloads `console.js` and `version.txt` when the version changed.
5. Requires the cached `console.js`.
6. Reuses the cached file if the network is unavailable.

## Cache Invalidation

The cache updates when the remote `version.txt` differs from the cached version. This keeps updates predictable without introducing package management.

## Implementation Philosophy

The utility is a single CommonJS file, depends only on Node.js built-ins, and uses ANSI escape codes directly.
