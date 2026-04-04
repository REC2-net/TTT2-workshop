# Trouble in Terrorist Town 2 (TTT2) Workflow Guide

This document outlines the solo development workflow specifically tailored for **Trouble in Terrorist Town 2 (TTT2)** addons. It supplements the main [Garry's Mod Workflow](Garrys_Mod.md) by diving into TTT2-specific architecture, hooks, and testing protocols.

---

## 1. TTT2 Addon Architecture

TTT2 introduces a modernized, modular approach to Garry's Mod development. Adhere to the following conventions:

### 1.1 Project Structure

TTT2 automatically loads specific subdirectories to prevent conflicts. Organize your code into:

```text
my_ttt2_addon/
├── addon.json
├── icon.png
├── lua/
│   └── terrortown/
│       ├── autorun/
│       │   ├── client/      # Client-side only (HUD, UI)
│       │   ├── server/      # Server-side only (Logic, networking)
│       │   └── shared/      # Shared state and constants
│       ├── entities/
│       │   ├── items/       # Passive items and equipment
│       │   └── roles/       # Custom roles
│       └── menus/           # F1 Menu configurations
```

_Note: Using `lua/terrortown/autorun/` eliminates the need for manual `AddCSLuaFile()` calls._

### 1.2 Dependency Management

- Ensure the base `terrortown` gamemode and `TTT2` are loaded before executing logic.
- Hook into `TTT2Initialize` instead of standard `Initialize` or `InitPostEntity` to guarantee TTT2 core libraries are available.

---

## 2. Development Workflow (TTT2 Focus)

### 2.1 Local Environment Setup

- Symlink your addon into the `garrysmod/addons/` directory.
- Use **Visual Studio Code** with the **glualint** extension.
- Validate your code against `.trae/rules/03-glua-quality.md`.

### 2.2 TTT2 Coding Standards

- **Roles**: When creating roles, inherit from the base `ROLE` table. Define standard properties like `color`, `abbr`, `radarColor`, and `score`.
- **Items**: Utilize the modular item system. Passive items should define `ITEM.EquipMenuData` for the shop.
- **Global Namespace**: Avoid polluting `_G`. Prefix your variables or wrap them in localized tables.

### 2.3 Automated Testing Protocols

- **Dry-Run Testing**: Use the `scripts/validate_addons.js` to ensure the structure meets Workshop and TTT2 standards.
- **In-Game Validation**:
  - Spawn multiple bots using `bot` in the server console to test role distribution.
  - Test UI elements across different resolutions (e.g., 1080p vs 1440p) to ensure the TTT2 HUD scaling is respected.

---

## 3. Quality Assurance Checklist

Before finalizing a TTT2 addon, verify the following:

- [ ] Code is formatted with `stylua` and passes `glualint`.
- [ ] No cross-addon dependencies exist (except `/packages/` imports handled by the build script).
- [ ] Network strings are prefixed with the addon name (e.g., `net.Receive("MyAddon_TTT2_Sync", ...)`).
- [ ] `addon.json` correctly categorizes the addon (usually `gamemode` or `weapon` with the `roleplay` tag).

---

## 4. Release & Post-Publication

- **Release Management**: Merge from `feat/*` into `main`. The CI/CD pipeline (using `gmod-workshop-cicd`) will auto-publish the `.gma` to the Steam Workshop.
- **Monitoring**: Actively monitor the Steam Workshop comments and GitHub Issues. Use the `fix/*` branch for hotfixes.

---

_Synchronized with [Main README](README.md) and [Garry's Mod Workflow](Garrys_Mod.md)._
