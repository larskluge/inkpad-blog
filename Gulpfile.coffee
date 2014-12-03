path = require('path')
Promise = require('bluebird')
_ = require('lodash')
del = require('del')
moment = require('moment')
streamify = require('stream-array')
through2 = require('through2')
gulp = require('gulp')
handlebars = require('gulp-compile-handlebars')
rename = require('gulp-rename')

inkpad = require('./lib/inkpad')
util = require('./lib/util')


data =
  perPage: 3
  inkpads: {}
  posts: []

handlebarsOptions =
  helpers:
    datetime: (timestamp, format) ->
      format = 'YYYY-MM-DD' unless _.isString(format)
      moment(timestamp).format(format)


paths =
  build: path.join(__dirname, '_build')
  templates:
    index: path.join(__dirname, 'templates/index.html')
    show: path.join(__dirname, 'templates/show.html')



gulp.task "clean", (cb) ->
  del "#{paths.build}/*", cb


gulp.task "load:inkpads", ["clean"], ->
  reg = inkpad.registry()

  streamify([id: "VoAXbudYb2"])
    .pipe reg
    .pipe inkpad.loadPads()
    .pipe inkpad.scanForSubPages(reg)
    .pipe inkpad.slicePads()
    .pipe inkpad.extractTitle()
    .pipe inkpad.extractTime()
    .pipe inkpad.extractTeaser()
    .pipe inkpad.extractHeaderImage()
    .pipe util.buffer()
    .pipe through2.obj (pad, enc, done) ->
      data.inkpads[pad.id] = pad
      done()

gulp.task "load:posts", ["load:inkpads"], ->
  data.posts = (data.inkpads[id] for id in data.inkpads["VoAXbudYb2"].linkedInkpads)

gulp.task "load", ["load:inkpads", "load:posts"]


gulp.task "templates:index", ["load"], ->
  pages = _.chain(data.posts).groupBy((n,i) -> i // data.perPage).values().value()
  Promise.all pages
    .each (posts, i) ->
      d = posts: posts
      page = i + 1
      path = if page == 1 then "/" else "/page/#{page}"
      lastPage = page == pages.length

      unless lastPage
        d.nextPageLink = "/page/#{page + 1}"

      switch
        when page == 2
          d.prevPageLink = "/"
        when page > 2
          d.prevPageLink = "/page/#{page - 1}"

      gulp.src paths.templates.index
        .pipe handlebars(d, handlebarsOptions)
        .pipe rename("#{path}/index.html")
        .pipe gulp.dest(paths.build)

gulp.task "templates:show", ["load"], ->
  Promise.all data.posts
    .each (post) ->
      gulp.src paths.templates.show
        .pipe handlebars(post: post, availableKeys: _.keys(post), handlebarsOptions)
        .pipe rename("#{post.path}/index.html")
        .pipe gulp.dest(paths.build)

gulp.task "templates", ["templates:index", "templates:show"]


gulp.task "default", ["templates"]

