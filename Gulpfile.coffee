path = require('path')
Promise = require('bluebird')
del = require('del')
streamify = require('stream-array')
through2 = require('through2')
gulp = require('gulp')
handlebars = require('gulp-compile-handlebars')
inkpad = require('./lib/inkpad')
util = require('./lib/util')


data =
  inkpads: {}
  posts: []


paths =
  build: path.join(__dirname, '_build')
  template: path.join(__dirname, 'template', '*')



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

gulp.task "load:posts", ["load:inkpads"], ->
  data.posts = (data.inkpads[id] for id in data.inkpads["VoAXbudYb2"].linkedInkpads)

gulp.task "load", ["load:inkpads", "load:posts"]


gulp.task "template", ["load"], ->
  gulp.src paths.template
    .pipe handlebars(data, helpers: {})
    .pipe gulp.dest(paths.build)


gulp.task "default", ["template"]



gulp.on 'err', (e) ->
  console.log(e.err.stack)

