cfg = 
  host: '10.57.96.221'
  port: 26123
  immediate: process.argv.length > 2
  'script patterns': [
    'scripts/common.js'
    'scripts/steel/common/*.js'
    'scripts/steel/*.js'
  ]
  # 'script patterns': [
  #   'scripts/common.js'
  #   'scripts/steel/common/*.js'
  #   'scripts/steel/zy-zhaogang.js'
  # ]

io = require('socket.io-client').connect "http://#{cfg.host}:#{cfg.port}/admin", cfg
rl = require('readline').createInterface
  input: process.stdin
  output: process.stdout
  terminal: true
fs = require 'fs'
glob = require 'glob'
compress = require 'compress-buffer'

concatScripts = (patterns) ->
  scripts = []
  patterns.forEach (pattern) ->
    glob.sync(pattern).forEach (filename) ->
      scripts.push '\n'
      scripts.push fs.readFileSync(filename)
  scripts.join ''

runCommand = (command, arg) ->
  switch command
    when 'start', 'stop', 'status', 'unload', 'refresh' then io.emit command, arg
    when 'update' then io.emit command, concatScripts(cfg['script patterns'])
    when 'load'
      eval concatScripts(cfg['script patterns'])
      io.emit command, arg, compress.compress(new Buffer(JSON.stringify(generateUrlConfig(arg))))
    when 'exit' then process.exit 0
    else 
      console.log 'ERR: unknown command'
      true

io
.on 'connect', ->
  if not cfg.immediate
    rl.setPrompt (if cfg.host then cfg.host else '') + '> '
    rl.prompt()
    rl.on 'line', (line) ->
      parts = line.trim().split ' '
      command = parts[0]
      arg = parts[1]

      rl.prompt() if runCommand command, arg
  else
    command = process.argv[2]
    arg = process.argv[3]
    process.exit 1 if runCommand command, arg

.on 'disconnect', ->
  console.warn 'disconnect.'
  process.exit 1

.on 'result', (data) ->
  console.log data
  if not cfg.immediate then rl.prompt() else prompt.exit 0
  
.on 'message', (message) ->
  console.log "\n#{message}"