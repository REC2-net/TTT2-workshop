---
alwaysApply: false
globs: **/addon.json, **/*.png, **/*.jpg
description: "Rules for Garry's Mod Steam Workshop standards and addon metadata."
---

# GMod Workshop Standards

## 1. Addon Metadata

- **addon.json**: Must be present in every addon root. Must contain valid JSON with `title`, `type`, `tags`, and `ignore` arrays.
- **Dynamic Adaptation**: Structure must match the `type` declared in `addon.json` (e.g., `lua/weapons/`, `lua/entities/`, `materials/`, `models/`, `sound/`, `maps/`).

## 2. Workshop Limits

- **File Size**: Individual `.gma` files must not exceed 200 MB.
- **Icon**: The workshop icon (`icon.png` or `icon.jpg`) must be exactly 512x512 pixels.

## 3. Legacy Content

- **Banned Files**: Legacy DLLs (`.dll`) are strictly prohibited.
