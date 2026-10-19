const fs = require("fs");

const manifest = JSON.parse(fs.readFileSync(0, "utf8")) || {};

const dependencies = Object.fromEntries(
  Object.entries(manifest.dependencies || {})
    .map(([name, info]) => [name, info.version])
    .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)),
);

process.stdout.write(JSON.stringify({ dependencies }, null, 2) + "\n");
