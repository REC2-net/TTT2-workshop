import {
  chmodSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
} from "node:fs";
import { join, resolve } from "node:path";

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
    return (asset: ReleaseAsset) =>
      asset.name === `glualint-${version}-OSX-x86_64.tar.gz`;
  }

  throw new Error(`Unsupported platform: ${platform}`);
}

async function fetchRelease(version: string): Promise<GithubRelease> {
  const response = await fetch(
    `https://api.github.com/repos/FPtje/GLuaFixer/releases/tags/${version}`,
    {
      headers: {
        Accept: "application/vnd.github+json",
        "User-Agent": "ttt2-workshop-tooling",
      },
    },
  );

  if (!response.ok) {
    throw new Error(
      `Failed to fetch glualint release metadata for ${version}: ${response.status} ${response.statusText}`,
    );
  }

  return (await response.json()) as GithubRelease;
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
  bun scripts/glualint.ts lint [glualint args...]
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
    const exitCode = await runGlualint(repoRoot, rest);
    process.exit(exitCode);
  }

  throw new Error(`Unknown command: ${command}`);
}

await main();
