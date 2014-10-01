module.exports = (grunt) ->
  grunt.initConfig 
    pkg: grunt.file.readJSON 'package.json'

    coffee: 
      glob_to_multiple:
        options: 
          bare: true
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'dest/'
        ext: '.js'
    watch:
      coffee: 
        files: '**/*.coffee'
        tasks: ['coffee']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
