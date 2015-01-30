path = require("path")
spawn = require("child_process").spawn

gulpPath = path.resolve(__dirname, "../node_modules/.bin/gulp")
forwardedArguments = process.argv.slice(2)
gulpfile = path.resolve(__dirname, "../Gulpfile.js")
argv = ["--gulpfile", gulpfile].concat(forwardedArguments)
def = require('../package.json')



module.exports =
  run: ->
    if "--version" in argv
      console.log def.version
    else
      console.log "#{def.name}@#{def.version}"
      console.log gulpPath, argv.join(" ")
      spawn gulpPath, argv, stdio: ["ignore", process.stdout, process.stderr]

