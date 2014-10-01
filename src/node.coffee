cfg = 
  crawlServerHost: '222.73.83.188'
  crawlServerPort: 26123
  name: "node-#{require('os').hostname()}"

  # host: 'testws.baostar.com'
  host: 'www.shgt.com'
  port: 80
  # host: '127.0.0.1'
  # port: 8000
  'reconnection delay': 5000
  'max reconnection attempts': Infinity
  batch: 1

io = require('socket.io-client').connect "http://#{cfg.crawlServerHost}:#{cfg.crawlServerPort}/node"
sha1 = require 'sha1'
gzip = require('zlib').gzip
http = require 'http'
request = require 'request'

script = ''
realWorker = (domain, url, urlConfig, crawlResult) ->
  crawlResult '脚本未实现'

stackObjects = []
commitObjects = (io) ->
  origin = JSON.stringify stackObjects.splice(0)

  request 
    url: "http://#{cfg.host}:#{cfg.port}/query/crawl-package/"
    method: 'POST'
    form: 
      origin: origin
      token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiVDIwNDMzMDAxIn0.X2Gb_zzyP-AqYN-a3069wO5xn1flEQml9c91nZF88Zg'
  , (err, response, body) ->
    console.log body
    logger 'info', body, io
    
    if err
      return logger 'error', 'commit failed!'

    stackObjects = []

    logger 'info', "=====send to server's data length: #{JSON.stringify(origin).length}" , io
    # console.log '==========start===========\n', origin, '\n=====================end================='
  

logger = (typ, msg, io) ->
  io.emit 'log', typ, "[#{cfg.name}] #{msg}" if io
  console.log msg


io
.on 'connect', ->
  logger 'info', 'connected', io
  io.emit 'login', cfg.name

.on 'disconnect', ->
  logger 'info', 'disconnect. commit the remaining.', io
  commitObjects()

.on 'update', (newScript) ->
  backup = 
    script: script
    worker: realWorker
  try
    eval newScript
    realWorker = worker
    logger 'info', 'update success', io
    script = newScript
  catch e
    logger "info", "update error #{JSON.stringify(e)}", io
    script = backup.script
    realWorker = backup.worker
  io.emit 'update result', sha1(script)

.on 'crawl', (domain, url, urlConfig) ->
  crawlResult = (err, domain, url, objects) ->
    io.emit 'crawl result', err, domain, url
    console.log objects.length if objects
    stackObjects = stackObjects.concat objects
    commitObjects() if stackObjects.length >= cfg.batch

  try
    logger 'info', "crawl #{domain} #{url}", io
    realWorker domain, url, urlConfig, crawlResult
  catch e
    logger 'info', "*** worker error *** #{e}", io
    console.log e
    crawlResult e, domain, url

setInterval ->
  if not io.connected
    console.log 'retyring...'
    io.connect "http://#{cfg.crawlServerHost}:#{cfg.crawlServerPort}/node"
, cfg['reconnection delay']
  