---
alwaysApply: false
globs: **/addon.json,**/*.png,**/*.jpg,**/materials/**,**/models/**,**/sound/**
---

# GMod Workshop Standards & Assets

## 1. Addon Metadata & Preparation

- **addon.json**: Must be present in every addon root. Must contain valid JSON with `title`, `type`, `tags`, and `ignore` arrays.
- **Dynamic Adaptation**: Structure must match the `type` declared in `addon.json` (e.g., `lua/weapons/`, `lua/entities/`, `materials/`, `models/`, `sound/`, `maps/`).
- **Workshop Tagging**: Ensure accurate tags (e.g., `roleplay`, `fun`, `weapon`) to maximize search visibility.

## 2. Workshop Limits

- **File Size**: Individual `.gma` files must not exceed 200 MB.
- **Icon**: The workshop icon (`icon.png` or `icon.jpg`) must be exactly 512x512 pixels. Keep the design clean and easily readable at small resolutions.

## 3. Asset Organization Conventions

- **Namespacing**: Prefix all custom materials, models, and sounds with your addon name to avoid conflicts (e.g., `materials/my_addon_name/icon.vmt`).
- **File Formats**: Use `.vtf` and `.vmt` for materials. `.mdl`, `.vvd`, `.vtx` for models. `.wav` or `.mp3` (44100Hz) for sounds.
- **Compression**: Optimize textures and sounds before packaging. Use appropriate compression flags in `.vtf` files (e.g., DXT1/DXT5).
- **Paths**: Never use uppercase letters in asset paths or filenames. Garry's Mod on Linux is case-sensitive, which will cause missing assets if casing is mismatched.

## 4. Legacy Content

- **Banned Files**: Legacy DLLs (`.dll`) are strictly prohibited.
