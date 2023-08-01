const { execSync } = require("child_process")
const fs = require("fs")

var commandString = "moonwave build --publish"
var codeString = " --code"
var spaceString = " "

function addCodePath(path) {
  commandString += codeString + spaceString + path
}

function scanInitialSrc() {
  fs.readdirSync("src").forEach(function(file) {
    addCodePath("src"+"/"+file+"/src")
  })
}

const run = (cwd, command) =>
  execSync(command, {
    cwd,
    stdio: "inherit",
  })

console.log("[release.js] Attempting publish build")

scanInitialSrc()
run(process.cwd(), commandString)