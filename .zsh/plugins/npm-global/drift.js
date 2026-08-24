// Prints missing, drifted, and untracked lines for the manifest argument. The globals root is derived from the node
// binary, so no npm invocation is needed.

const fs = require('fs')
const path = require('path')

const dir = path.resolve(process.execPath, '..', '..', 'lib', 'node_modules')
const tracked = require(process.argv[2]).dependencies || {}
const installed = {}

const entries = path => {
  try {
    return fs.readdirSync(path)
  } catch {
    return []
  }
}

const version = name => {
  try {
    return require(path.join(dir, name, 'package.json')).version || null
  } catch {
    return null
  }
}

for (const entry of entries(dir)) {
  if (entry.startsWith('.')) continue
  const names = entry.startsWith('@') ? entries(path.join(dir, entry)).map(sub => `${entry}/${sub}`) : [entry]
  for (const name of names) {
    if (fs.existsSync(path.join(dir, name, 'package.json'))) {
      installed[name] = version(name)
    }
  }
}

for (const [name, version] of Object.entries(tracked)) {
  if (!(name in installed)) {
    console.log(`missing ${name}@${version}`)
    continue
  }
  if (installed[name] && installed[name] !== version) {
    console.log(`drifted ${name}@${version} (installed ${installed[name]})`)
  }
}

for (const [name, version] of Object.entries(installed)) {
  if (!(name in tracked)) {
    console.log(`untracked ${version ? `${name}@${version}` : name}`)
  }
}
