---
alwaysApply: true
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
- **Branching**: Use specific branch names for the solo workflow: `main` for production releases, `feat/*` for new additions, `fix/*` for patches, and `workshop/*` for Steam integration changes.
- **Artifacts**: CI pipelines must generate `.gma` artifacts, compute CRC32 and SHA-256 file hashes, and auto-increment the workshop version.
- **Automated Publication**: Utilize `ghcr.io/linventif/gmod-workshop-cicd:latest` or similar docker images for automated Steam Workshop uploads on push to `main`.

## 3. Dependency Management

- **Bun as Default**: Use `bun` instead of `npm` or `yarn` for all scripting, tooling, and node dependencies in the monorepo.
- **TypeScript**: Use TypeScript (`.ts`) instead of JavaScript for all CI/CD and utility scripts.
- **TTT2 Dependencies**: Ensure that any TTT2 addon explicitly states its dependency on the base TTT2 gamemode and correctly hooks into `TTT2Initialize` or uses the `terrortown/` autoload structure.

## 4. Community Collaboration Protocols

- **Issue Tracking**: Use clear templates for bugs and feature requests.
- **Pull Requests**: Even in solo development, use PRs for major features to trigger CI/CD dry runs and validate the code before merging to `main`.
- **Code Reviews**: Perform self-reviews against the GLua Quality Gates and Security checklists before merging.
