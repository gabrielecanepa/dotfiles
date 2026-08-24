// Turns `npm list --global --json` on stdin into a sorted dependencies manifest. Exits 1 when empty.

const deps = JSON.parse(require('fs').readFileSync(0, 'utf8')).dependencies || {}
const sorted = Object.fromEntries(
  Object.entries(deps)
    .map(([name, info]) => [name, info.version])
    .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
)
if (!Object.keys(sorted).length) process.exit(1)
process.stdout.write(JSON.stringify({ dependencies: sorted }, null, 2) + '\n')
