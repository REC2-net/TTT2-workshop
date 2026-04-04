const fs = require("fs");
const path = require("path");
const Validator = require("./validate_addons");

const MOCK_ROOT = path.join(__dirname, "mock_repo");

function setupMockRepo() {
  if (fs.existsSync(MOCK_ROOT)) {
    fs.rmSync(MOCK_ROOT, { recursive: true, force: true });
  }
  fs.mkdirSync(MOCK_ROOT, { recursive: true });

  // Valid Addon
  const validAddon = path.join(MOCK_ROOT, "valid_addon");
  fs.mkdirSync(validAddon);
  fs.writeFileSync(
    path.join(validAddon, "addon.json"),
    JSON.stringify({ title: "Valid", type: "weapon" }),
  );

  // Create 512x512 PNG mock
  const pngBuffer = Buffer.alloc(33);
  pngBuffer.write("PNG", 1, 3, "ascii");
  pngBuffer.writeUInt32BE(512, 16); // Width
  pngBuffer.writeUInt32BE(512, 20); // Height
  fs.writeFileSync(path.join(validAddon, "icon.png"), pngBuffer);

  fs.mkdirSync(path.join(validAddon, "lua"));
  fs.writeFileSync(
    path.join(validAddon, "lua", "init.lua"),
    'print("Hello World")\n',
  );

  // Invalid Addon
  const invalidAddon = path.join(MOCK_ROOT, "invalid_addon");
  fs.mkdirSync(invalidAddon);
  fs.writeFileSync(path.join(invalidAddon, "addon.json"), '{"invalid": true}'); // Missing title/type
  // Missing icon
  fs.writeFileSync(path.join(invalidAddon, "legacy.dll"), "binary data");
  fs.mkdirSync(path.join(invalidAddon, "lua"));
  fs.writeFileSync(
    path.join(invalidAddon, "lua", "bad.lua"),
    'local key = "A1B2C3D4E5F6A1B2C3D4E5F6A1B2C3D4"\ninclude("../valid_addon/lua/init.lua")',
  );
}

function runTests() {
  console.log("Setting up mock repository...");
  setupMockRepo();

  console.log("Running validator against mock repository...");
  const validator = new Validator(MOCK_ROOT);
  validator.run();

  let passed = true;
  const expectedErrors = [
    'addon.json must contain "title" and "type".',
    "Missing icon.png or icon.jpg (512x512).",
    "Legacy .dll files are strictly banned.",
    "Potential Steam API Key found.",
    "Cross-addon imports detected via parent directory inclusion.",
  ];

  const errorMessages = validator.errors.map((e) => e.message);

  for (const expected of expectedErrors) {
    if (!errorMessages.includes(expected)) {
      console.error(`❌ Expected error not found: "${expected}"`);
      passed = false;
    } else {
      console.log(`✅ Caught expected error: "${expected}"`);
    }
  }

  // Check that valid addon had NO errors
  const validAddonErrors = validator.errors.filter((e) =>
    e.file.startsWith("valid_addon"),
  );
  if (validAddonErrors.length > 0) {
    console.error(`❌ Valid addon had unexpected errors:`, validAddonErrors);
    passed = false;
  } else {
    console.log(`✅ Valid addon passed with 0 errors.`);
  }

  fs.rmSync(MOCK_ROOT, { recursive: true, force: true });

  if (passed) {
    console.log("\n🎉 All tests passed successfully!");
    process.exit(0);
  } else {
    console.error("\n💥 Tests failed!");
    process.exit(1);
  }
}

runTests();
