---
alwaysApply: false
globs: "**/*.lua"
description: "GLua code quality, formatting, and linting rules."
---

# GLua Quality Gates

## 1. Encoding

- **UTF-8**: All `.lua` files MUST be encoded in UTF-8 (without BOM) to prevent parsing errors in Garry's Mod.

## 2. Formatting & Linting

- **glualint**: Code must pass `glualint` without warnings.
- **stylua**: Code must be formatted using `stylua`.
- **TTT2 Standards**: Follow TTT2 specific API conventions and avoid global namespace pollution. Use localized functions where possible.
