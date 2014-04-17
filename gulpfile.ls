gulp          = require 'gulp'
browserify    = require 'gulp-browserify'
ls            = require 'gulp-livescript'
connect       = require 'gulp-connect'

rename        = require 'gulp-rename'
uglify        = require 'gulp-uglify'


dest = './dist'

gulp.task 'ls', ->
  gulp.src 'src/**.ls'
    .pipe ls!
    .on 'error' -> throw it
    .pipe gulp.dest dest

gulp.task 'main', ['ls'], ->
  gulp.src dest + '/main.js'
    .pipe browserify!
    .pipe rename {suffix: '.bundle'}
    .pipe gulp.dest dest
    #.pipe uglify!
    #.pipe rename {suffix: '.min'}
    #.pipe gulp.dest dest
    .pipe connect.reload!


gulp.task 'connect', ->
  connect.server do
    root: dest
    livereload: true

gulp.task 'watch', ['connect'], ->
  gulp.watch 'src/**.ls', ['main']
