path = require('path')
Promise = require('bluebird')
del = require('del')
gulp = require('gulp')
streamify = require('stream-array')
through2 = require('through2')
inkpad = require('./lib/inkpad')
util = require('./lib/util')


data =
  inkpads: {}


paths =
  build: path.join(__dirname, '_build')



gulp.task "clean", (cb) ->
  del "#{paths.build}/*", cb


gulp.task "load:inkpads", ->
  reg = inkpad.registry()

  streamify([id: "VoAXbudYb2"])
    .pipe reg
    .pipe inkpad.loadPads()
    .pipe inkpad.scanForSubPages(reg)
    .pipe inkpad.slicePads()
    .pipe inkpad.extractTitle()
    .pipe util.buffer()
    .pipe through2.obj (pad, enc, done) ->
      data.inkpads[pad.id] = pad
      done()

gulp.task "load", ["load:inkpads"]


gulp.task "default", ["load"]



gulp.on 'err', (e) ->
  console.log(e.err.stack)

