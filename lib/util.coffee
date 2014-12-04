through2 = require "through2"
gutil = require "gulp-util"


buffer = ->
  all = []

  transform = (obj, enc, done) ->
    all.push obj
    done()

  flush = (done) ->
    for obj in all
      @push obj
    done()

  through2.obj transform, flush



log = (name) ->
  firstRun = true

  transform = (obj, enc, done) ->
    if firstRun
      gutil.log "#{name}: Starting..."
      firstRun = false

    gutil.log "#{name}:", obj
    @push obj
    done()

  flush = (done) ->
    gutil.log "#{name}: Finished."
    done()

  through2.obj transform, flush



module.exports =
  buffer: buffer
  log: log

