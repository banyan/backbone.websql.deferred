"use strict"
module.exports = (grunt) ->

  grunt.initConfig
    indent:
      scripts:
        src: [
          'src/utils.coffee'
          'src/main.coffee'
        ]
        dest: 'tmp/'
        options:
          style: 'space'
          size: 2
          change: 1

    concat:
      options:
        separator: ';'
      sources:
        options:
          separator: '' # override
        src: [
          'src/entry.coffee'
          'tmp/utils.coffee'
          'tmp/main.coffee'
        ]
        dest: 'tmp/backbone.websql.deferred.coffee'

      deps:
        src: [
          'node_modules/jquery/dist/jquery.js'
          'node_modules/underscore/underscore.js'
          'node_modules/backbone/backbone.js'
        ]
        dest: 'vendor/vendor.js'
      depsForTest:
        src: [
          'node_modules/mocha/mocha.js'
          'node_modules/sinon/lib/sinon.js'
          'node_modules/chai/chai.js'
          'node_modules/sinon-chai/lib/sinon-chai.js'
        ]
        dest: 'vendor/test-vendor.js'
      depsForCSS:
        src: [
          'node_modules/mocha/mocha.css'
        ]
        dest: 'vendor/test.css'

    coffee:
      compile:
        files:
          'lib/backbone.websql.deferred.js': 'tmp/backbone.websql.deferred.coffee'
          'test/lib/backbone.websql.deferred-test.js': 'test/src/backbone.websql.deferred-test.coffee'

    watch:
      src:
        files: ["src/*.coffee", "test/src/*.coffee"]
        tasks: ["build"]

    shell:
      'mocha-phantomjs':
        command: 'mocha-phantomjs test/index.html'
        options:
          stdout: true
          stderr: true

  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-simple-mocha"
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-indent'

  grunt.registerTask "default", ["watch"]
  grunt.registerTask "build",   ["indent", "concat", "coffee"]
  grunt.registerTask "test",    ["build", "shell:mocha-phantomjs"]
