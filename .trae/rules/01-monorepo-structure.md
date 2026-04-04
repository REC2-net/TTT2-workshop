---
alwaysApply: true
description: "Monorepo structure, Conventional Commits, and CI/CD rules for TTT2 addons."
---

# Monorepo & CI/CD Rules

## 1. Monorepo Structure

- **Isolation**: Each addon must reside in its own isolated directory under the repository root (e.g., `/my-addon/`).
- **Shared Libraries**: Place all shared code or libraries in the `/packages/` directory.
- **No Cross-Imports**: Addons must not import or depend directly on files from another addon's directory.
- **Build Output**: Compiled artifacts must be isolated to `<addon_name>/workshop/`.

## 2. CI/CD & Versioning

- **Commits**: Strictly follow Conventional Commits (`feat:`, `fix:`, `chore:`, etc.).
- **Changelogs**: Steam changelogs must be ≤ 8000 characters. Auto-generate release summaries.
- **Branching**: Adapt logic based on branch names (`feat/*`, `fix/*`, `workshop/*`, `release/*`).
- **Artifacts**: CI pipelines must generate `.gma` artifacts, compute CRC32 and SHA-256 file hashes, and auto-increment the workshop version.
