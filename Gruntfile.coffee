"use strict"
module.exports = (grunt) ->

  grunt.initConfig
    coffee:
      lib:
        options:
          bare: true
        expand: true
        cwd: 'src',
        src: ["*.coffee"]
        dest: "lib"
        ext: ".js"

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
