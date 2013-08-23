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
  }

  
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-concat')

  # Default task(s).
  grunt.registerTask('default', ['coffee', 'concat'])
