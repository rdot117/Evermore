const { execSync } = require("child_process")
const fs = require("fs")

var DEV_STRING = "moonwave dev"
var PUBLISH_STRING = "moonwave build --public"

var commandString = PUBLISH_STRING
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