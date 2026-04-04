# Trouble in Terrorist Town 2 (TTT2) Workshop Addons Monorepo

Welcome to the **TTT2 Workshop Addons Monorepo**. This repository serves as the centralized, production-grade workspace for developing, validating, and managing Trouble in Terrorist Town 2 (TTT2) addons for Garry's Mod.

This repository enforces strict CI/CD pipelines, modular design, and robust quality gates to guarantee stability, security, and seamless deployment to the [Steam Workshop](https://steamcommunity.com/workshop/).

---

## 📑 Table of Contents

1. [Architecture Overview](#-architecture-overview)
2. [Prerequisites](#-prerequisites)
3. [Setup Instructions](#-setup-instructions)
4. [Available Scripts](#-available-scripts)
5. [Steam Workshop Integration](#-steam-workshop-integration)
6. [Contribution Guidelines](#-contribution-guidelines)
7. [Troubleshooting](#-troubleshooting)
8. [Helpful Links](#-helpful-links)

---

## 🏗 Architecture Overview

This project is structured as a **monorepo**, meaning multiple distinct Garry's Mod addons are versioned and managed together within the same Git repository.

### Directory Structure

```text
/Users/florentin/Repositories/REC2-net/TTT2-workshop
├── .trae/                 # IDE-specific configurations and project rules
│   └── rules/             # Markdown rules enforcing GLua quality, security, and structure
├── packages/              # Shared libraries and reusable GLua modules
├── scripts/               # Node.js CI/CD scripts for validation and building
│   ├── validate_addons.js # Dry-runs rules against every addon
│   └── validate_addons.test.js
├── my_ttt2_addon_1/       # An isolated Garry's Mod addon directory
│   ├── addon.json         # Workshop metadata (title, type, tags)
│   ├── icon.png           # 512x512 Workshop icon
│   ├── lua/               # Addon source code
│   └── workshop/          # Generated .gma build output
└── my_ttt2_addon_2/       # Another isolated addon
```

### Package Interactions

- **Isolation**: Each addon (e.g., `my_ttt2_addon_1`) acts as a completely independent module. Cross-addon imports (e.g., `include("../../other_addon/lua/file.lua")`) are strictly forbidden to prevent deployment conflicts.
- **Shared Libraries (`/packages`)**: Code shared across multiple addons is developed in the `/packages` directory. During the CI/CD build phase, these shared libraries are bundled into the individual addons' `workshop/` outputs.

---

## 📋 Prerequisites

To develop, test, and validate addons locally, you will need the following tools installed:

- **[Node.js](https://nodejs.org/)** (v16+): Required for running the validation and CI/CD scripts.
- **[Garry's Mod](https://store.steampowered.com/app/4000/Garrys_Mod/)**: Required for local testing.
- **[gmpublish.exe](https://wiki.facepunch.com/gmod/Workshop_Addon_Updating)**: (Included in Garry's Mod `bin` folder) Required to manually pack `.gma` files or upload to the Workshop.
- **[glualint](https://github.com/FPtje/GLuaFixer)** & **[stylua](https://github.com/JohnnyMorganz/StyLua)**: Required for linting and formatting GLua code.
- **Code Editor**: We recommend [Visual Studio Code](https://code.visualstudio.com/) with the **GLua Enhanced** and **GLuaLint** extensions.

---

## 🚀 Setup Instructions

Follow these steps to get your local environment running:

1. **Clone the Repository**

   ```bash
   git clone git@github.com:REC2-net/TTT2-workshop.git
   cd TTT2-workshop
   ```

2. **Initialize Dependencies**
   (If any NPM packages are added later for CI, install them here)

   ```bash
   # bun install
   ```

3. **Symlink to Garry's Mod (Optional but Recommended)**
   To test your addons live in Garry's Mod without copying files repeatedly, create a symlink from the addon directory to your Garry's Mod `addons` folder.

   _Windows (Command Prompt as Admin):_

   ```cmd
   mklink /D "C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\addons\my_ttt2_addon" "C:\path\to\TTT2-workshop\my_ttt2_addon"
   ```

   _macOS/Linux:_

   ```bash
   ln -s /Users/florentin/Repositories/REC2-net/TTT2-workshop/my_ttt2_addon ~/Library/Application\ Support/Steam/steamapps/common/GarrysMod/garrysmod/addons/my_ttt2_addon
   ```

---

## 🛠 Available Scripts

We provide Node.js scripts to ensure that no broken addons are pushed to the Workshop.

### Validate Addons

Runs the compliance suite against all addons in the monorepo. It checks for file sizes (<200MB), icon dimensions (512x512), valid UTF-8 encoding, legacy `.dll` files, and hardcoded API keys.

```bash
node scripts/validate_addons.js
```

### Run Validator Tests

Executes the test suite for the validation script itself using a mock repository.

```bash
node scripts/validate_addons.test.js
```

---

## 🌐 Steam Workshop Integration

This repository is optimized to interact seamlessly with the [Steam Workshop](https://steamcommunity.com/workshop/).

- **Addon Metadata (`addon.json`)**: Every addon must declare its title, type, and ignored files. Our validation scripts verify this file before allowing a build.
- **Compatibility & Versioning**: Following recent [Steam Workshop updates](https://steamcommunity.com/workshop/), addons can specify compatibility with historical game branch versions. We track versioning via Conventional Commits and auto-increment versions during the `.gma` build phase.
- **Workshop Collections**: For players using multiple addons from this repository, we recommend organizing them into Workshop Collections for easy subscription management.
- **Change Notes**: CI/CD auto-generates release summaries. Keep in mind that Steam restricts change notes to ≤ 8000 characters and US-ASCII characters to prevent upload failures.

---

## 🤝 Contribution Guidelines

We welcome contributions! To ensure high-quality standards, please adhere to the following rules:

1. **Branch Naming**:
   Use prefixes such as `feat/`, `fix/`, `workshop/`, or `release/`.
   _Example: `feat/new-traitor-weapon`_

2. **Conventional Commits**:
   All commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/).
   _Example: `feat(weapons): add silenced pistol to traitor shop`_

3. **GLua Quality Gates**:
   - All `.lua` files must be **UTF-8 encoded** (without BOM).
   - Code must pass `glualint` with zero warnings.
   - Code must be formatted using `stylua`.
   - Avoid global namespace pollution; utilize TTT2's localized hooks and functions.

4. **Security**:
   - Do not redistribute copyrighted Valve assets or decompiled BSP content.
   - **Never** hardcode Steam API keys. The validation script will flag and block 32-character hexadecimal strings resembling API keys.

---

## 🚑 Troubleshooting

| Issue                                                          | Cause                                                      | Solution                                                                                                                    |
| -------------------------------------------------------------- | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Validation Error:** `Icon dimensions must be 512x512`        | The `icon.png` or `icon.jpg` is the wrong size.            | Resize your image to exactly 512x512 pixels. This is a strict Garry's Mod Workshop requirement.                             |
| **Validation Error:** `File contains invalid UTF-8 characters` | A `.lua` file was saved with the wrong encoding.           | Open the file in VS Code, click the encoding in the bottom right corner, select "Save with Encoding", and choose **UTF-8**. |
| **Validation Error:** `Cross-addon imports detected`           | You used `include("../other_addon/...")`.                  | Addons must be isolated. Move the shared logic to `/packages/` and import it properly.                                      |
| **Garry's Mod ignores my `.lua` file**                         | The file is missing the `.lua` extension or is `.lua.txt`. | Check the "File name extensions" box in your OS File Explorer to ensure the file ends in exactly `.lua`.                    |

---

## 📚 Helpful Links

- **[Garry's Mod Official Wiki](https://wiki.facepunch.com/gmod/)**
- **[Workshop Addon Updating Guide](https://wiki.facepunch.com/gmod/Workshop_Addon_Updating)**
- **[TTT2 Official Documentation](https://docs.ttt2.neoxult.de/)**
- **[GLua Basics & Getting Started](https://wiki.facepunch.com/gmod/Beginner_Tutorial_Intro)**
- **[Steam Workshop Guidelines](https://steamcommunity.com/workshop/)**

---

_Maintained by the REC2.net Team._
