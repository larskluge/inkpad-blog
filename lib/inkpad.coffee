through2 = require "through2"
Promise = require "bluebird"
req = Promise.promisifyAll(require "request")
cheerio = require "cheerio"
url = require "url"
gutil = require "gulp-util"
_ = require "lodash"



Inkpad =

  extractIds: ->
    through2.obj (file, enc, done) ->
      file.contents.toString().replace /inkpads.*([a-z0-9]{10})/ig, (m, id) =>
        @push id: id
      done()



  allLoaded: (pads) ->
    for id, pad of pads
      if !pad.loaded
        return false
    true



  registry: ->
    pads = {}

    transform = (pad, enc, done) ->
      if !pads[pad.id]
        pad.loaded = false
        pads[pad.id] = pad
        @push pad
      done()

    flush = (done) ->
      fn = ->
        if Inkpad.allLoaded pads
          done()
        else
          setTimeout fn, 100
      fn()

    r = through2.obj transform, flush
    r.addPad = (pad) ->
      transform.call r, pad, null, ->
      pads[pad.id].path = pad.path
    r



  loadPads: ->
    pads = {}

    transform = (pad, enc, done) ->
      id = pad.id
      pad.loaded = false
      pads[id] = pad

      uri = "http://www.inkpad.io/#{id}"
      gutil.log "[inkpad] Loading #{uri}"

      self = @
      req.getAsync(uri)
        .spread (resp, body) ->
          pad.contents = body
          pad.loaded = true
          self.push pad

      done()

    flush = (done) ->
      fn = ->
        if Inkpad.allLoaded pads
          done()
        else
          setTimeout ->
            fn()
          , 100
      fn()

    through2.obj transform, flush



  scanForSubPages: (reg) ->

    transform = (pad, enc, done) ->
      $ = cheerio.load(pad.contents)
      $('a[href*="inkpad.io"]').each ->
        relPath = $(@).attr 'title'
        uri = $(@).attr 'href'
        match = url.parse(uri).pathname.match /^\/([a-z0-9]{10})/i

        if relPath?.search(/^\//) >= 0 and match
          id = match[1]
          $(@).attr 'href', relPath
          $(@).removeAttr 'title'
          pad.linkedInkpads ||= []
          pad.linkedInkpads.push id
          reg.addPad id: id, path: relPath

      pad.contents = $.html()
      @push pad
      done()

    through2.obj transform



  slicePads: ->

    transform = (pad, enc, done) ->
      $ = cheerio.load(pad.contents)
      pad.contents = $(".markdown-body").html()
      pad.normalizedContents = pad.contents
      @push pad
      done()

    through2.obj transform



  extractTitle: ->

    transform = (pad, enc, done) ->
      $ = cheerio.load(pad.normalizedContents)
      titleEl = $("h1,h2,h3,h4,h5,h6").first()
      title = titleEl.text()
      pad.title = title
      titleEl.remove()
      pad.normalizedContents = $.html()
      @push pad
      done()

    through2.obj transform



  extractTimestamp: ->

    transform = (pad, enc, done) ->
      $ = cheerio.load(pad.normalizedContents)
      el = $("time").first()
      time = el.attr("datetime") or el.text()
      if time
        pad.timestamp = new Date(time)
        el.remove()
        pad.normalizedContents = $.html()
      @push pad
      done()

    through2.obj transform



  extractHeaderImage: ->

    transform = (pad, enc, done) ->
      $ = cheerio.load(pad.normalizedContents)

      el = $('img[alt*="header" i]').first()
      if el
        pad.headerImageUrl = el.attr("src")
        el.remove()
        pad.normalizedContents = $.html()
      @push pad
      done()

    through2.obj transform



  extractTeaser: ->

    transform = (pad, enc, done) ->
      $ = cheerio.load(pad.normalizedContents)
      text = $("p").text().substring(0, 255).replace(/\s\w+$/, '')
      pad.teaser = text
      @push pad
      done()

    through2.obj transform



module.exports = Inkpad

