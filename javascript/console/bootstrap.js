const fs = require('fs')
const os = require('os')
const path = require('path')
const { execFileSync } = require('child_process')

const remoteBaseUrl = 'https://raw.githubusercontent.com/poziel/dev-utils/main/javascript/console'
const cacheDir = path.join(os.homedir(), '.cache', 'dev-utils', 'javascript', 'console')

function cachedPath(fileName) {
  return path.join(cacheDir, fileName)
}

function readLocalVersion() {
  const versionPath = cachedPath('version.txt')
  if (!fs.existsSync(versionPath)) {
    return null
  }

  return fs.readFileSync(versionPath, 'utf8').trim()
}

function readRemoteText(fileName) {
  const url = `${remoteBaseUrl}/${fileName}`
  const script = `
    const https = require('https');
    https.get(${JSON.stringify(url)}, (response) => {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        console.error('Request failed with status ' + response.statusCode);
        process.exit(1);
      }
      let body = '';
      response.setEncoding('utf8');
      response.on('data', (chunk) => { body += chunk; });
      response.on('end', () => { process.stdout.write(body.trim()); });
    }).on('error', (error) => {
      console.error(error.message);
      process.exit(1);
    });
  `

  return execFileSync(process.execPath, ['-e', script], { encoding: 'utf8' }).trim()
}

function downloadFile(fileName) {
  const url = `${remoteBaseUrl}/${fileName}`
  const outputPath = cachedPath(fileName)
  const script = `
    const fs = require('fs');
    const https = require('https');
    const output = fs.createWriteStream(${JSON.stringify(outputPath)});
    https.get(${JSON.stringify(url)}, (response) => {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        output.close();
        fs.rmSync(${JSON.stringify(outputPath)}, { force: true });
        console.error('Request failed with status ' + response.statusCode);
        process.exit(1);
      }
      response.pipe(output);
      output.on('finish', () => output.close());
    }).on('error', (error) => {
      output.close();
      fs.rmSync(${JSON.stringify(outputPath)}, { force: true });
      console.error(error.message);
      process.exit(1);
    });
  `

  execFileSync(process.execPath, ['-e', script], { stdio: ['ignore', 'ignore', 'pipe'] })
}

function updateCacheIfNeeded() {
  fs.mkdirSync(cacheDir, { recursive: true })

  let remoteVersion
  try {
    remoteVersion = readRemoteText('version.txt')
  } catch (error) {
    if (fs.existsSync(cachedPath('console.js'))) {
      return
    }

    throw new Error(
      'Console utility is not cached and could not be downloaded. Check your network connection and try again.'
    )
  }

  if (readLocalVersion() === remoteVersion) {
    return
  }

  downloadFile('console.js')
  downloadFile('version.txt')
}

updateCacheIfNeeded()

const consolePath = cachedPath('console.js')
if (!fs.existsSync(consolePath)) {
  throw new Error(`Cached console implementation was not found: ${consolePath}`)
}

module.exports = require(consolePath)
