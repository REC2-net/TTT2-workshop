# TTT2 Workshop Addon Rules

This directory contains the production-grade TRAE Project Rules configured for the TTT2 Workshop addons monorepo.

## Overview

The rules ensure the monorepo adheres to strict Workshop standards, security practices, and CI/CD pipelines.
They are executed automatically by TRAE IDE during your workflow to guarantee compliance.

- `01-monorepo-structure.md`: Enforces directory isolation and conventional commits.
- `02-gmod-workshop.md`: Validates `addon.json`, 512x512 icons, and 200MB `.gma` limits.
- `03-glua-quality.md`: Ensures UTF-8 encoding and GLua linting.
- `04-security-legal.md`: Blocks Valve IP leaks and Steam API keys.

## Validation Script

To validate addons locally or in CI/CD, use the Node.js script located at `/scripts/validate_addons.js`:

```bash
node scripts/validate_addons.js
```

It returns `0` on success or `1` if violations are found, along with GitHub Action annotations.

## Local Overrides

If you need to bypass a rule temporarily:

1. Use `.traeignore` at the root of the specific addon to skip validation.
2. In PRs, use the `--no-verify` flag in your local workflow, but note that the CI pipeline will still enforce the rules.
