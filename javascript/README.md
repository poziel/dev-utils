# JavaScript Utilities

This folder contains lightweight JavaScript helper utilities for Node.js scripts, setup tasks, automation, and CLI workflows.

## Available Utilities

- `console` - ANSI-colored console output helpers for sections, status messages, warnings, and errors.

## Bootstrap Usage

```javascript
const Console = require('./bootstrap')

Console.section('Setup')
Console.info('Checking environment')
Console.success('Ready')
```

Run this from the `javascript/console` folder or place `bootstrap.js` next to your script.

## Cache Location

JavaScript utilities are cached under:

```txt
~/.cache/dev-utils/javascript
```

The console utility uses:

```txt
~/.cache/dev-utils/javascript/console
```

## Architecture

JavaScript utilities use CommonJS-compatible files and small static class APIs. No npm dependencies are required.

## Extension Philosophy

Future utilities should stay dependency-free unless a dependency is clearly justified. Prefer direct Node.js standard-library APIs, readable files, and stable copy-friendly interfaces.
