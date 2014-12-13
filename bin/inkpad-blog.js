#!/usr/bin/env node


var path = require("path");
var spawn = require("child_process").spawn;

var gulpPath = path.resolve(__dirname, "../node_modules/.bin/gulp");
var forwardedArguments = process.argv.slice(2);
var gulpfile = path.resolve(__dirname, "../Gulpfile.js");
var argv = ["--gulpfile", gulpfile].concat(forwardedArguments);


console.log(gulpPath, argv.join(" "));
spawn(gulpPath, argv, {stdio: ["ignore", process.stdout, process.stderr]});

