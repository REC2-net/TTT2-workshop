const fs = require("fs");
const path = require("path");

class Validator {
  constructor(rootDir) {
    this.rootDir = rootDir;
    this.hasErrors = false;
    this.errors = [];
  }

  reportError(file, message) {
    const errorMsg = `::error file=${file}::${message}`;
    console.error(errorMsg);
    this.errors.push({ file, message });
    this.hasErrors = true;
  }

  checkIconDimensions(iconPath) {
    if (!fs.existsSync(iconPath)) return;
    if (iconPath.endsWith(".png")) {
      const buffer = fs.readFileSync(iconPath);
      if (buffer.length > 24 && buffer.toString("ascii", 1, 4) === "PNG") {
        const width = buffer.readUInt32BE(16);
        const height = buffer.readUInt32BE(20);
        if (width !== 512 || height !== 512) {
          this.reportError(
            iconPath,
            `Icon dimensions must be 512x512. Found ${width}x${height}`,
          );
        }
      }
    }
    // Basic check for jpg is just existence for now, unless using an image parsing library
  }

  scanDirectory(dir, isAddonRoot = false, addonName = "") {
    if (!fs.existsSync(dir)) return;
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      const relativePath = path.relative(this.rootDir, fullPath);

      if (entry.isDirectory()) {
        if (isAddonRoot && entry.name === "workshop") continue;
        this.scanDirectory(fullPath, false, addonName);
      } else {
        const stats = fs.statSync(fullPath);
        if (stats.size > 200 * 1024 * 1024) {
          this.reportError(
            relativePath,
            `File exceeds 200MB limit (${(stats.size / 1024 / 1024).toFixed(2)}MB)`,
          );
        }

        if (entry.name.endsWith(".dll")) {
          this.reportError(
            relativePath,
            "Legacy .dll files are strictly banned.",
          );
        }

        if (entry.name.endsWith(".lua")) {
          const content = fs.readFileSync(fullPath);
          const text = content.toString("utf8");

          if (text.includes("\uFFFD")) {
            this.reportError(
              relativePath,
              "File contains invalid UTF-8 characters.",
            );
          }

          const apiKeyRegex = /\b[0-9A-F]{32}\b/gi;
          if (apiKeyRegex.test(text)) {
            this.reportError(relativePath, `Potential Steam API Key found.`);
          }

          if (text.includes('include("../') || text.includes('include( "../')) {
            this.reportError(
              relativePath,
              "Cross-addon imports detected via parent directory inclusion.",
            );
          }
        }
      }
    }
  }

  validateAddon(addonDir) {
    const addonName = path.basename(addonDir);
    const addonJsonPath = path.join(addonDir, "addon.json");
    const relativeAddonJson = path.relative(this.rootDir, addonJsonPath);

    if (!fs.existsSync(addonJsonPath)) {
      this.reportError(relativeAddonJson, "Missing addon.json metadata file.");
    } else {
      try {
        const metadata = JSON.parse(fs.readFileSync(addonJsonPath, "utf8"));
        if (!metadata.title || !metadata.type) {
          this.reportError(
            relativeAddonJson,
            'addon.json must contain "title" and "type".',
          );
        }
      } catch (e) {
        this.reportError(
          relativeAddonJson,
          `Invalid JSON in addon.json: ${e.message}`,
        );
      }
    }

    const iconPng = path.join(addonDir, "icon.png");
    const iconJpg = path.join(addonDir, "icon.jpg");

    if (fs.existsSync(iconPng)) this.checkIconDimensions(iconPng);
    if (fs.existsSync(iconJpg)) this.checkIconDimensions(iconJpg);
    if (!fs.existsSync(iconPng) && !fs.existsSync(iconJpg)) {
      this.reportError(
        path.relative(this.rootDir, addonDir),
        "Missing icon.png or icon.jpg (512x512).",
      );
    }

    this.scanDirectory(addonDir, true, addonName);
  }

  run() {
    const excludedDirs = [
      ".git",
      ".trae",
      "scripts",
      "packages",
      "node_modules",
      "tools",
    ];
    if (!fs.existsSync(this.rootDir)) return true;
    const rootEntries = fs.readdirSync(this.rootDir, { withFileTypes: true });

    for (const entry of rootEntries) {
      if (entry.isDirectory() && !excludedDirs.includes(entry.name)) {
        this.validateAddon(path.join(this.rootDir, entry.name));
      }
    }
    return !this.hasErrors;
  }
}

if (require.main === module) {
  const targetDir = process.argv[2] || path.resolve(__dirname, "..");
  const validator = new Validator(targetDir);
  const success = validator.run();
  if (success) {
    console.log("All addons passed validation successfully.");
  } else {
    console.error("Validation failed with errors.");
  }
  process.exit(success ? 0 : 1);
}

module.exports = Validator;
