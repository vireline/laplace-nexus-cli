# Contributing to Laplace Nexus CLI

Thanks for contributing.

## Ground rules
- No illegal or malicious defaults.
- Keep descriptions educational and neutral.
- Prefer Debian/Parrot-compatible tooling (apt) where possible.
- Do not include secrets/tokens/keys in commits.

## Adding a tool
Preferred methods:
1) Add to `plugins/*.plugin` (recommended)
2) Add to built-in menus if it’s core

Plugin format:
`category|tool|description|example`

## Style
- Keep menu names short
- Keep examples safe by default (no real targets)
- Run a quick syntax check:
  ```bash
  bash -n laplace.sh
