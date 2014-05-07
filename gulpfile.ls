gulp          = require 'gulp'
browserify    = require 'gulp-browserify'
ls            = require 'gulp-livescript'
connect       = require 'gulp-connect'
rename        = require 'gulp-rename'
uglify        = require 'gulp-uglify'
mocha         = require 'gulp-mocha'
less          = require 'gulp-less'
jade          = require 'gulp-jade'

dist = './dist'

err = (e)->
  console.error e
  this.emit 'end'

gulp.task 'js', ->
  gulp.src 'src/**/*.js'
    .pipe gulp.dest "#{dist}/js"

gulp.task 'ls', ->
  gulp.src 'src/**/*.ls'
    .pipe ls!.on('error', err)
    .pipe gulp.dest "#{dist}/js"

gulp.task 'test', ['js', 'ls'], ->
  # Run unit tests first
  gulp.src "#{dist}/js/test/unit-*.js"
    .pipe mocha!
  # Compile browser tests
  gulp.src "#{dist}/js/test/test.js"
    .pipe browserify!
    .pipe rename {suffix: '.bundle'}
    .pipe gulp.dest "#{dist}/test"
    #.pipe connect.reload!

/*
gulp.task 'browsertest', ->
  gulp.src "#{dist}/test/index.html"
    .pipe mochaPhantom!
*/

gulp.task 'main', ['ls'], ->
  gulp.src "#{dist}/js/main.js"
    .pipe browserify!
    .pipe rename {suffix: '.bundle'}
    .pipe gulp.dest dist
    #.pipe uglify!
    #.pipe rename {suffix: '.min'}
    #.pipe gulp.dest dest
    .pipe connect.reload!

gulp.task 'less', ->
  gulp.src "styles/teztura.less"
    .pipe less!.on('error', err)
    .pipe gulp.dest "#{dist}/css"
    .pipe connect.reload!

gulp.task 'templates', ->
  gulp.src "templates/index.jade"
    .pipe jade {
      pretty: true
    }
    .pipe gulp.dest "#{dist}"
    .pipe connect.reload!

gulp.task 'bootstrap', ->
  gulp.src "styles/bootstrap/bootstrap.less"
    .pipe less!.on('error', err)
    .pipe gulp.dest "#{dist}/css"
    .pipe connect.reload!

gulp.task 'connect', ->
  connect.server do
    root: dist
    port: 8000
    livereload: true

gulp.task 'serve', ['test', 'main', 'connect'], ->
  gulp.watch ['src/**/*'], ['test', 'main']
  gulp.watch ['styles/*.less'], ['less']
  gulp.watch ['styles/bootstrap/*.less'], ['bootstrap']
  gulp.watch ['templates/*.jade'], ['templates']

