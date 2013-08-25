module.exports = (grunt)->
  # Project configuration.

  grunt.initConfig {
    pkg: grunt.file.readJSON('package.json'),

    coffee:
      compile:
        options: 
          bare: true
          join: true
          sourceMap: true
        files:
          'out/js/teztura-core.js': ['src/core/*.coffee'],
          'out/js/teztura.js': ['src/*.coffee'],

    concat:
      dist:
        src: ['src/renderers/*.js'],
        dest: 'out/js/teztura-renderers.js',

    watch:
      coffee:
        files: ['src/core/*.coffee', 'src/*.coffee']
        tasks: ['coffee']
        options:
          livereload: true

      concat:
        files: ['src/renderers/*.js']
        tasks: ['concat']
        options:
          livereload: true
          
    connect:
      site:
        options:
          port: 8000
          base: 'out'

  }

  
  grunt.loadNpmTasks('grunt-contrib-connect')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-concat')
  grunt.loadNpmTasks('grunt-contrib-watch')

  # Default task(s).
  grunt.registerTask('default', ['coffee', 'concat'])
  grunt.registerTask('live', ['connect', 'watch'])
