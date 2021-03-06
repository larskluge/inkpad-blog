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
deploy = require('gulp-gh-pages')
minimist = require('minimist')
fs = require('fs')
os = require('os')
exec = Promise.promisify(require('child_process').exec)
ps = require('promise-streams')


inkpad = require('./lib/inkpad')
util = require('./lib/util')


knownOptions =
  string: ['id', 'per-page', 'templates-path', 'deploy-to']
  alias:
    'inkpadId': 'id'
  default:
    'templates-path': path.join(__dirname, 'templates')

options = minimist(process.argv.slice(2), knownOptions)


data =
  perPage: parseInt(options['per-page'], 10) or 3
  inkpads: {}
  posts: []

handlebarsOptions =
  helpers:
    datetime: (timestamp, format) ->
      format = 'YYYY-MM-DD' unless _.isString(format)
      moment(timestamp).format(format)


templatesPath = path.resolve process.env.INIT_CWD, options['templates-path']
paths =
  build: path.join(__dirname, '_build')
  templates:
    index: path.join(templatesPath, 'index.html.handlebars')
    show: path.join(templatesPath, 'show.html.handlebars')
    public: path.join(templatesPath, 'public', '**', '*')



gulp.task "check:templates:index", ->
  unless fs.existsSync paths.templates.index
    console.log "Index template not found, expected index.html.handlebars to be in '#{templatesPath}'."
    process.exit(1)

gulp.task "check:templates:show", ->
  unless fs.existsSync paths.templates.show
    console.log "Show template not found, expected show.html.handlebars to be in '#{templatesPath}'."
    process.exit(1)

gulp.task "check:templates", ["check:templates:index", "check:templates:show"]

gulp.task "check", ["check:templates"]


gulp.task "clean", ["check"], (cb) ->
  del "#{paths.build}/*", cb


gulp.task "load:inkpads", ["clean"], ->
  reg = inkpad.registry()

  streamify([id: options.inkpadId])
    .pipe reg
    .pipe inkpad.loadPads()
    .pipe inkpad.scanForSubPages(reg)
    .pipe inkpad.slicePads()
    .pipe inkpad.extractTitle()
    .pipe inkpad.extractTimestamp()
    .pipe inkpad.extractHeaderImage()
    .pipe inkpad.extractTeaser()
    .pipe util.buffer()
    .pipe through2.obj (pad, enc, done) ->
      data.inkpads[pad.id] = pad
      done()

gulp.task "load:posts", ["load:inkpads"], ->
  data.posts = (data.inkpads[id] for id in data.inkpads[options.inkpadId].linkedInkpads)

gulp.task "load", ["load:inkpads", "load:posts"]


gulp.task "templates:index", ["load"], ->
  pages = _.chain(data.posts).groupBy((n,i) -> i // data.perPage).values().value()
  Promise.all pages
    .map (posts, i) ->
      d = posts: posts
      page = i + 1
      destPath = if page == 1 then "/" else "/page/#{page}"
      lastPage = page == pages.length

      unless lastPage
        d.nextPageLink = "/page/#{page + 1}/"

      switch
        when page == 2
          d.prevPageLink = "/"
        when page > 2
          d.prevPageLink = "/page/#{page - 1}/"

      gulp.src paths.templates.index
        .pipe handlebars(d, handlebarsOptions)
        .pipe rename("#{destPath}/index.html")
        .pipe gulp.dest(paths.build)
    .map (stream) ->
      ps.wait(stream)

gulp.task "templates:show", ["load"], ->
  Promise.all data.posts
    .map (post, i) ->
      d = post: post, availableKeys: _.keys(post)

      prevPost = data.posts[i - 1]
      nextPost = data.posts[i + 1]
      if prevPost
        d.prevPostLink = prevPost.path
      if nextPost
        d.nextPostLink = nextPost.path

      gulp.src paths.templates.show
        .pipe handlebars(d, handlebarsOptions)
        .pipe rename("#{post.path}/index.html")
        .pipe gulp.dest(paths.build)
    .map (stream) ->
      ps.wait(stream)

gulp.task "templates", ["templates:index", "templates:show"]


gulp.task "copy", ["clean"], ->
  gulp.src paths.templates.public
    .pipe gulp.dest(paths.build)


gulp.task "compile", ["templates", "copy"]


gulp.task "update:deploy-repo", ->
  deployRepoPath = path.join(os.tmpdir(), "tmpRepo")
  if fs.existsSync deployRepoPath
    if fs.existsSync path.join(deployRepoPath, ".git")
      exec("git pull", cwd: deployRepoPath)
        .catch (e) ->
          console.log "Deleting the deploy repository (#{deployRepoPath}); please re-run the command to get a freshly cloned one."
    else
      del.sync deployRepoPath, force: true


gulp.task "deploy", ["compile", "update:deploy-repo"], ->
  gulp.src path.join(paths.build, "**/*")
    .pipe deploy(remoteUrl: options['deploy-to'])


gulp.task "default", ["compile"]

