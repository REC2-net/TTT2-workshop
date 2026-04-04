import {
  chmodSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  statSync,
} from "node:fs";
import { isAbsolute, join, relative, resolve } from "node:path";

type ReleaseAsset = {
  name: string;
  browser_download_url: string;
};

type GithubRelease = {
  assets: ReleaseAsset[];
};

function readGlualintVersionFromPackageJson(repoRoot: string): string {
  const packageJsonPath = join(repoRoot, "package.json");
  const raw = readFileSync(packageJsonPath, "utf8");
  const parsed = JSON.parse(raw) as { config?: { glualintVersion?: string } };
  const version = parsed.config?.glualintVersion;
  if (!version || typeof version !== "string") {
    throw new Error(
      `Missing package.json config.glualintVersion (${packageJsonPath})`,
    );
  }
  return version;
}

function toolDir(repoRoot: string, version: string): string {
  return join(repoRoot, ".tools", "glualint", version);
}

function toolBinaryPath(repoRoot: string, version: string): string {
  const binName = process.platform === "win32" ? "glualint.exe" : "glualint";
  return join(toolDir(repoRoot, version), binName);
}

function spawnChecked(command: string, args: string[], cwd: string) {
  const result = Bun.spawnSync([command, ...args], {
    cwd,
    stdout: "inherit",
    stderr: "inherit",
    stdin: "inherit",
  });

  if (result.exitCode !== 0) {
    throw new Error(
      `Command failed (${result.exitCode}): ${command} ${args.join(" ")}`,
    );
  }
}

function platformAssetPredicate(version: string) {
  const platform = process.platform;
  const arch = process.arch;

  if (platform === "win32") {
    return (asset: ReleaseAsset) =>
      asset.name === `glualint-${version}-Windows.zip`;
  }

  if (platform === "linux") {
    if (arch === "arm64") {
      return (asset: ReleaseAsset) =>
        asset.name === `glualint-${version}-aarch64-linux.zip`;
    }

    return (asset: ReleaseAsset) =>
      asset.name === `glualint-${version}-x86_64-linux.zip`;
  }

  if (platform === "darwin") {
    if (arch === "arm64") {
      // Check if native arm64 build exists, fallback to x86_64 via Rosetta
      return (asset: ReleaseAsset) =>
        asset.name === `glualint-${version}-OSX-arm64.tar.gz` ||
        asset.name === `glualint-${version}-OSX-x86_64.tar.gz`;
    }
    return (asset: ReleaseAsset) =>
      asset.name === `glualint-${version}-OSX-x86_64.tar.gz`;
  }

  throw new Error(`Unsupported platform: ${platform}`);
}

async function fetchRelease(version: string): Promise<GithubRelease> {
  const timeoutMs = 30_000;
  const controller = new AbortController();
  const timeoutId = setTimeout(() => {
    controller.abort();
  }, timeoutMs);

  try {
    const response = await fetch(
      `https://api.github.com/repos/FPtje/GLuaFixer/releases/tags/${version}`,
      {
        headers: {
          Accept: "application/vnd.github+json",
          "User-Agent": "ttt2-workshop-tooling",
        },
        signal: controller.signal,
      },
    );

    if (!response.ok) {
      throw new Error(
        `Failed to fetch glualint release metadata for ${version}: ${response.status} ${response.statusText}`,
      );
    }

    return (await response.json()) as GithubRelease;
  } catch (error) {
    const isAbortError =
      (error instanceof DOMException && error.name === "AbortError") ||
      (error instanceof Error && error.name === "AbortError");

    if (isAbortError) {
      throw new Error(
        `Failed to fetch glualint release metadata for ${version}: request timed out after ${timeoutMs}ms`,
      );
    }

    if (
      error instanceof Error &&
      error.message.startsWith(
        `Failed to fetch glualint release metadata for ${version}:`,
      )
    ) {
      throw error;
    }

    throw new Error(
      `Failed to fetch glualint release metadata for ${version}: request failed (${
        error instanceof Error ? error.message : String(error)
      })`,
    );
  } finally {
    clearTimeout(timeoutId);
  }
}

async function downloadFile(url: string, outputPath: string): Promise<void> {
  const response = await fetch(url, {
    headers: {
      "User-Agent": "ttt2-workshop-tooling",
    },
  });

  if (!response.ok) {
    throw new Error(
      `Failed downloading ${url}: ${response.status} ${response.statusText}`,
    );
  }

  const arrayBuffer = await response.arrayBuffer();
  await Bun.write(outputPath, new Uint8Array(arrayBuffer));
}

function listFilesRecursive(dir: string): string[] {
  const out: string[] = [];
  const entries = readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...listFilesRecursive(path));
    } else if (entry.isFile()) {
      out.push(path);
    }
  }
  return out;
}

function findFirstBasename(dir: string, basename: string): string | undefined {
  const all = listFilesRecursive(dir);
  return all.find(
    (p) => p.endsWith(`/${basename}`) || p.endsWith(`\\${basename}`),
  );
}

async function installGlualint(repoRoot: string): Promise<string> {
  const version = readGlualintVersionFromPackageJson(repoRoot);
  const binPath = toolBinaryPath(repoRoot, version);

  if (existsSync(binPath)) {
    return binPath;
  }

  const targetDir = toolDir(repoRoot, version);
  mkdirSync(targetDir, { recursive: true });

  const release = await fetchRelease(version);
  const asset = release.assets.find(platformAssetPredicate(version));
  if (!asset) {
    const available = release.assets.map((a) => a.name).join(", ");
    throw new Error(
      `No glualint asset found for ${process.platform}/${process.arch}. Available: ${available}`,
    );
  }

  const isZip = asset.name.endsWith(".zip");
  const archivePath = join(
    targetDir,
    isZip ? "glualint.zip" : "glualint.tar.gz",
  );

  await downloadFile(asset.browser_download_url, archivePath);

  if (isZip) {
    try {
      spawnChecked("unzip", ["-o", archivePath, "-d", targetDir], repoRoot);
    } catch (unzipError) {
      console.warn("unzip failed, falling back to tar:", unzipError);
      spawnChecked("tar", ["-xf", archivePath, "-C", targetDir], repoRoot);
    }
  } else {
    spawnChecked("tar", ["-xzf", archivePath, "-C", targetDir], repoRoot);
  }

  const extractedBin = findFirstBasename(
    targetDir,
    process.platform === "win32" ? "glualint.exe" : "glualint",
  );
  if (!extractedBin) {
    throw new Error(
      `glualint binary not found after extracting ${archivePath}`,
    );
  }

  if (extractedBin !== binPath) {
    const file = Bun.file(extractedBin);
    await Bun.write(binPath, await file.arrayBuffer());
  }

  if (process.platform !== "win32") {
    chmodSync(binPath, 0o755);
  }

  return binPath;
}

async function runGlualint(repoRoot: string, args: string[]): Promise<number> {
  const version = readGlualintVersionFromPackageJson(repoRoot);
  const binPath = await installGlualint(repoRoot);

  const child = Bun.spawn([binPath, ...args], {
    cwd: repoRoot,
    stdout: "inherit",
    stderr: "inherit",
    stdin: "inherit",
    env: {
      ...process.env,
      GLUALINT_VERSION: version,
    },
  });

  return await child.exited;
}

type GlualintCliParseResult = {
  glualintArgs: string[];
  rawTargets: string[];
};

function parseGlualintCliArgs(
  repoRoot: string,
  args: string[],
): GlualintCliParseResult {
  const glualintArgs: string[] = [];
  const rawTargets: string[] = [];

  const flagsWithValue = new Set(["--config", "-c"]);

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (arg === "--") {
      rawTargets.push(...args.slice(i + 1));
      break;
    }

    if (flagsWithValue.has(arg)) {
      const value = args[i + 1];
      if (!value) {
        throw new Error(`Missing value for ${arg}`);
      }
      glualintArgs.push(arg, value);
      i++;
      continue;
    }

    if (arg.startsWith("-")) {
      glualintArgs.push(arg);
      continue;
    }

    if (arg.endsWith(".lua")) {
      rawTargets.push(arg);
      continue;
    }

    try {
      const resolved = isAbsolute(arg) ? arg : resolve(repoRoot, arg);
      if (existsSync(resolved) && statSync(resolved).isDirectory()) {
        rawTargets.push(arg);
      } else {
        glualintArgs.push(arg);
      }
    } catch {
      glualintArgs.push(arg);
    }
  }

  return { glualintArgs, rawTargets };
}

function normalizeTargetPath(repoRoot: string, inputPath: string): string {
  const absPath = isAbsolute(inputPath)
    ? inputPath
    : resolve(repoRoot, inputPath);
  const rel = relative(repoRoot, absPath);
  if (rel === "") {
    return ".";
  }
  if (!rel.startsWith("..") && !isAbsolute(rel)) {
    return rel;
  }
  return absPath;
}

function validateTargetPaths(repoRoot: string, rawTargets: string[]): string[] {
  const normalized: string[] = [];

  for (const raw of rawTargets) {
    const abs = isAbsolute(raw) ? raw : resolve(repoRoot, raw);
    if (!existsSync(abs)) {
      throw new Error(`Path does not exist: ${raw}`);
    }

    const stat = statSync(abs);
    if (stat.isDirectory()) {
      normalized.push(normalizeTargetPath(repoRoot, raw));
      continue;
    }

    if (stat.isFile()) {
      if (!raw.endsWith(".lua") && !abs.endsWith(".lua")) {
        throw new Error(`Not a .lua file: ${raw}`);
      }
      normalized.push(normalizeTargetPath(repoRoot, raw));
      continue;
    }

    throw new Error(`Unsupported path type: ${raw}`);
  }

  return normalized;
}

async function main() {
  const repoRoot = resolve(import.meta.dir, "..");
  const [command, ...rest] = process.argv.slice(2);

  if (
    !command ||
    command === "help" ||
    command === "--help" ||
    command === "-h"
  ) {
    console.log(`Usage:
  bun scripts/glualint.ts install
  bun scripts/glualint.ts lint [glualint args...] [paths...]
  bun scripts/glualint.ts version`);
    process.exit(0);
  }

  if (command === "install") {
    const binPath = await installGlualint(repoRoot);
    console.log(binPath);
    return;
  }

  if (command === "version") {
    const exitCode = await runGlualint(repoRoot, ["--version"]);
    process.exit(exitCode);
  }

  if (command === "lint") {
    const { glualintArgs, rawTargets } = parseGlualintCliArgs(repoRoot, rest);
    const targets = validateTargetPaths(repoRoot, rawTargets);
    const args = targets.length > 0 ? [...glualintArgs, ...targets] : rest;
    const exitCode = await runGlualint(repoRoot, args);
    process.exit(exitCode);
  }

  throw new Error(`Unknown command: ${command}`);
}

await main();
