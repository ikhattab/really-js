gulp = require 'gulp'
$ = require('gulp-load-plugins')()
karma = require('karma').server
browserify = require 'browserify'
watchify = require 'watchify'
coffeeify = require 'coffeeify'
through2 = require 'through2'
del = require 'del'
pkg = require './package.json'
banner = """
          /*!
           *  Really.js v<%= pkg.version %>
           *  Copyright (C) 2014-2015 Really Inc. <http://really.io>
           *
           *  Date:  #{$.util.date()}
           */
          
          """

gulp.task 'tdd', ['lint'], (done) ->
  gulp.watch ['./src/**/*.coffee', './tests/**/*.coffee'], ['lint']
  # start the server
  $.nodemon 
    script: 'tests/support/server/index.js'
  .on 'restart', ->
    console.log 'restarted!'
  
  karma.start
    configFile: "#{__dirname}/karma.conf-tdd.js"
  , done

gulp.task 'test', ['lint'], (done) ->
  karma.start
    configFile: "#{__dirname}/karma.conf.js"
  , done

gulp.task 'browserify', ->
  gulp.src ['src/really.coffee']
    .pipe through2.obj (file, enc, next) ->
      # generate browserify uncompressed bundle
      browserify
        entries: [file.path]
        standalone: 'Really'
        extensions: ['.js', '.coffee']
      .transform('coffeeify')
      .bundle (err, res) ->
          file.contents = res
          next(null, file)
    
    .pipe $.rename 'really.js'
    # add banner to file
    .pipe $.header banner, {pkg}
    .pipe gulp.dest 'dist'
    .pipe $.uglify
      preserveComments: 'some'
      compress:
        drop_console: true
    # minified version of file
    .pipe $.rename "really.#{pkg.version}.min.js"
    .pipe gulp.dest 'dist'
  
gulp.task 'lint', ->
  gulp.src ['./src/**/*.coffee', './tests/**/*.coffee']
    .pipe $.coffeelint()
    .pipe $.notify  message: (file) ->
      unless file.coffeelint.success
        "Found #{file.coffeelint.errorCount} Errors and #{file.coffeelint.warningCount} Warnings"
  

# Clean Output Directory
gulp.task 'clean', del ['dist/*']

gulp.task 'lint-build', ->
  gulp.src ['./src/**/*.coffee', './tests/**/*.coffee']
    .pipe $.coffeelint.reporter('fail')


gulp.task 'build', ['clean', 'lint-build', 'browserify']
gulp.task 'default', ['build']
