"use strict"
module.exports = (grunt) ->

  grunt.initConfig
    coffee:
      compile:
        files:
          'lib/backbone.websql.deferred.js': 'src/backbone.websql.deferred.coffee'

    watch:
      src:
        files: "src/*.coffee"
        tasks: ["build"]

    simplemocha:
      all:
        src: ['test/**/*.coffee']
        options:
          require: 'test/test-helper'
          timeout: 3000
          ignoreLeaks: false
          ui: 'bdd'
          compilers: 'coffee:coffee-script'

  # These plugins provide necessary tasks.
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-simple-mocha"

  grunt.registerTask "default", ["watch"]
  grunt.registerTask "build",   ["coffee"]
  grunt.registerTask "test",    ["simplemocha"]
