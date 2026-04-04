# Garry's Mod End-to-End Development Workflow

This document provides a comprehensive guide to the solo development lifecycle for Garry's Mod addons within this monorepo. It focuses on repository initialization, branching strategies, CI/CD, and Steam Workshop management.

---

## 1. Repository & Branching Strategy

### 1.1 Monorepo Initialization

The workspace is structured as a monorepo to manage multiple addons.

- All node scripts and tooling utilize **Bun** and **TypeScript**.
- Addons are isolated in their respective root directories.
- Shared logic resides in `/packages/`.

### 1.2 Solo Branching Strategy

To maintain version control discipline while ensuring maximum velocity:

- `main`: The production branch. Pushing to this branch triggers the CI/CD pipeline for Workshop publication.
- `feat/<name>`: Used for developing new addons, roles, or features.
- `fix/<name>`: Used for rapid bug fixing.
- `workshop/<name>`: Used for updating metadata, icons, or descriptions without altering code.

_Even as a solo developer, use Pull Requests to merge into `main` to trigger automated CI checks._

---

## 2. Local Development & Automated Testing

### 2.1 Environment Configuration

- Symlink the addon directory to your local Garry's Mod `addons/` folder.
- Install [glualint](https://github.com/FPtje/GLuaFixer) and [stylua](https://github.com/JohnnyMorganz/StyLua).
- Ensure `.trae/rules/` are active in your IDE for real-time validation.

### 2.2 Automated Testing Protocols

Run the validation scripts to verify constraints before pushing:

```bash
bun run scripts/validate_addons.ts
```

The CI/CD pipeline enforces:

- File sizes (< 200MB).
- `addon.json` validity.
- 512x512 icon dimensions.
- Absence of legacy `.dll` files and Steam API keys.
- UTF-8 encoding compliance.

---

## 3. Steam Workshop Publication

### 3.1 Metadata Preparation

Every addon requires:

- An `icon.png` (512x512).
- An `addon.json` defining `title`, `type`, `tags`, and ignored files.
- Optimized assets (properly compressed `.vtf` materials and 44100Hz `.wav` sounds).

### 3.2 Build Process & CI/CD

We utilize a Docker-based GitHub Actions workflow (using `ghcr.io/linventif/gmod-workshop-cicd:latest`).

1. **Push to `main`**: Triggers the GitHub Action.
2. **Build Phase**: The pipeline bundles `/packages/` into the addon, generates a `.gma` file, and calculates file hashes.
3. **Publication**: The `gmod-workshop-cicd` container connects to SteamCMD using the encrypted `STEAM_SHARED_SECRET` and uploads/updates the item based on the `PUBLISHED_FILE_ID`.

### 3.3 Post-Publication Monitoring

- **Release Summaries**: Changelogs are auto-generated from Conventional Commits.
- **Monitoring**: Track GitHub Issues for bug reports. Use the `fix/*` workflow for deploying hotfixes.

---

_Synchronized with [Main README](README.md) and [TTT2 Workflow](TTT2.md)._
