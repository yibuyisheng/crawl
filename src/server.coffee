cfg = 
  port: 26123
  dispatchInterval: 1 * 1000
  reorderInterval: 30 * 1000

io = require('socket.io').listen(cfg.port)
sha1 = require 'sha1'
sprintf = require('sprintf').sprintf
compress = require 'compress-buffer'
logger = require './logger'
redis = require 'redis'
config = require './config'
Q = require 'q'

redisClient = redis.createClient config.redisPort, config.redisHost
redisClient.select config.redisDB
redisOperation = 
  get: (key, cb) ->
    return if not cb instanceof Function
    redisClient.get key, (err, result) ->
      return cb err if err
      cb err, JSON.parse(result)
  update: (key, cb, afterUpdateCb) ->
    return if not cb instanceof Function
    redisClient.get key, (err, result) ->
      if err
        cb err
      else 
        result = cb null, JSON.parse(result)
        redisClient.set key, JSON.stringify(result) if result isnt undefined

      afterUpdateCb err, result if afterUpdateCb instanceof Function

  qget: (key) ->
    deffered = Q.defer()
    @get key, (err, result) ->
      deffered.resolve 
        err: err
        result: result
    deffered.promise
  qupdate: (k, v) ->
    deffered = Q.defer()
    redisClient.set k, JSON.stringify(v), (err, res) ->
      deffered.resolve
        err: err
        res: res
    deffered.promise
      

# 初始化redis数据结构
redisOperation.qget 'server'
.then (data) ->
  throw data.err if data.err 
  redisOperation.qupdate 'server', {online: false, script: '', scriptHash: ''} if not data.result
.done()

# domains 数据结构
# {
#   'opsteel': {
#     'http://www.opsteel.cn/resource/': {
#       priority: 1,
#       validity: 10 * 60 * 1000,
#       check: 1403153690284,
#       state: [wait|crawling|error|success] // wait: 任务待分配，crawling: 抓取中，error: 抓取出错，success: 抓取成功
#     }
#   }
# }
redisOperation.qget 'domains'
.then (data) ->
  throw data.err if data.err 
  redisOperation.qupdate 'domains', {} if not data.result
.done()

# worklist 数据结构
# {'opsteel': [
#     ['http://www.opsteel.com/search', {check: 1403153690284, priority: 1, validity: 10 * 60 * 1000}],
#     ['http://www.opsteel.com/search/2', {check: 1403153690285, priority: 1, validity: 10 * 60 * 1000}]
#   ]
# }
redisOperation.qget 'worklist'
.then (data) ->
  throw data.err if data.err 
  redisOperation.qupdate 'worklist', {} if not data.result
.done()

redisOperation.qupdate 'nodes', {}

# 当前进程中所有socket的id和socket的映射:{socketId: socket}
allSockets = {}

reorder = ->
  # 对domains中需要抓取的域名进行优先级的排序，然后放置在worklist中
  now = new Date().getTime()
  worklist = {}

  logger.info '~~~~~ reorder begin~~~~~'
  redisOperation.qget 'domains'
  .then (data) ->
    throw data.err if data.err

    domains = data.result
    for domain, v of domains
      crawlUrls = []
      urlConfigs = domains[domain]

      for url, urlConfig of urlConfigs
        # 抓取时间限制，主要用于防止在非正常时间访问被发现
        if urlConfig and urlConfig.duration
          cur = new Date()
          # logger.info "===========time: #{cur.getHours() < urlConfig.duration.startHours or cur.getHours() > urlConfig.duration.endHours}"
          continue if cur.getHours() < urlConfig.duration.startHours or cur.getHours() > urlConfig.duration.endHours 

        crawlUrls.push [url, urlConfig] if urlConfig.check < now #and (urlConfig.state is 'wait' or urlConfig.state is 'error')

      crawlUrls.sort (v1, v2) ->
        if v1[1].priority > v2[1].priority then 1 else -1

      worklist[domain] = crawlUrls
      logger.info domain, crawlUrls.length

    # logger.info JSON.stringify(worklist)
    redisOperation.qupdate 'worklist', worklist
  .done ->
    logger.info '~~~~~ reorder end~~~~~'

setInterval reorder, cfg.reorderInterval

dispatch = ->
  # logger.info '~~~~~ dispatch begin~~~~~'
  redisOperation.qget 'server'
  .then (data) ->
    throw data.err if data.err

    server = data.result
    return if not server.online

    now = new Date().getTime()
    worklist = null
    domains = null
    redisOperation.qget 'worklist'
    .then (data) ->
      throw data.err if data.err

      worklist = data.result

      redisOperation.qget 'domains'
    .then (data) ->
      throw data.err if data.err

      domains = data.result

      redisOperation.qget 'nodes'
    .then (data) ->
      throw data.err if data.err

      nodes = data.result
      # 将worklist中的任务分配给当前闲置的节点
      for domain, v of worklist
        crawlUrls = worklist[domain]

        for socketId, v of nodes
          break if crawlUrls.length is 0
          continue if nodes[socketId].scriptHash isnt server.scriptHash or nodes[socketId].working[domain]

          # 分配了的任务就从worklist中移除
          crawlUrl = crawlUrls.splice(0, 1)[0]
          url = crawlUrl[0]
          urlConfig = crawlUrl[1]
          urlConfig.check = now + 3 * 60 * 1000
          allSockets[socketId].emit 'crawl', domain, url, urlConfig
          logger.info domain, '...' + url.slice(url.length - 30, url.length), '=== crawl ===>', socketId
          nodes[socketId].working[domain] = url

          # 分配了的任务就在domains中设置为抓取中的状态
          domains[domain][url].state = 'crawling'

      redisOperation.qupdate 'worklist', worklist
      # logger.info "====================nodes: #{JSON.stringify nodes}"
      redisOperation.qupdate 'nodes', nodes
    .catch (err) ->
      logger.error JSON.stringify(err)
    .done ->
      # logger.info '~~~~~ dispatch end~~~~~'

  
setInterval dispatch, cfg.dispatchInterval

io.of('/node').on 'connection', (socket) ->
  socket
  .on 'login', (name) ->
    logger.info socket.id, '=== login ===>', name
    # return if name isnt 'node-AY1406041547044683afZ'
    
    redisOperation.qget 'nodes'
    .then (data) ->
      throw data.err if data.err

      nodes = data.result
      nodes[socket.id] = 
        name: name
        scriptHash: ''
        working: {}
      allSockets[socket.id] = socket

      redisOperation.qupdate 'nodes', nodes
    .then (data) ->
      throw data.err if data.err

      redisOperation.qget 'server'
    .then (data) ->
      throw data.err if data.err

      server = data.result
      socket.emit 'update', server.script
    .done()

  .on 'disconnect', ->
    logger.info socket.id, '=== disconnect ===>'
    redisOperation.update 'nodes', (err, nodes) ->
      if err
        logger.error JSON.stringify(err)
        return
      delete nodes[socket.id]
      nodes
  .on 'update result', (scriptHash) ->
    return if not socket
    logger.info socket.id, '=== update ===>', scriptHash
    redisOperation.qget 'nodes'
    .then (data) ->
      throw data.err if data.err

      nodes = data.result
      nodes[socket.id].scriptHash = scriptHash
      redisOperation.qupdate 'nodes', nodes
    .done()
  .on 'crawl result', (errOrigin, domain, url) ->
    return if not socket or not socket.id 

    redisOperation.qget 'nodes'
    .then (data) ->
      throw data.err if data.err

      nodes = data.result
      return if not nodes[socket.id]

      nodeWorklist = nodes[socket.id].working
      delete nodeWorklist[domain] if nodeWorklist and nodeWorklist[domain]

      redisOperation.qupdate 'nodes', nodes

      redisOperation.qget 'domains'
      .then (data) ->
        throw data.err if data.err

        domains = data.result
        return if not domains[domain] or not domains[domain][url]
        crawlConfig = domains[domain][url]

        now = new Date().getTime()
        if errOrigin
          logger.info socket.id, '=== crawl result ===>', errOrigin, domain, '...' + url.slice(url.length - 30, url.length)
          crawlConfig.check = now
          crawlConfig.state = 'error'
        else
          crawlConfig.check = now + crawlConfig.validity
          crawlConfig.state = 'success'
          logger.info socket.id, '=== crawl result ===> success', '...' + url.slice(url.length - 30, url.length)

        redisOperation.qupdate 'domains', domains
  .on 'log', (typ, msg) ->
    logger[typ](msg) if logger[typ] instanceof Function



io.of('/admin').on 'connection', (socket) ->
  socket
  .on 'start', ->
    redisOperation.qget('server')
    .then (data) ->
      return logger.error JSON.stringify(data.err) if data.err
      server = data.result
      server.online = true
      redisOperation.qupdate('server', server)

      logger.info '***** ADMIN: start *****'
      socket.emit 'result', 'OK'
  .on 'stop', ->
    redisOperation.qget('server')
    .then (data) ->
      return logger.error JSON.stringify(data.err) if data.err
      server = data.result
      server.online = false
      redisOperation.qupdate('server', server)

      logger.info '***** ADMIN: stop *****'
      socket.emit 'result', 'OK'
  .on 'status', ->
    logger.info '***** ADMIN: status *****'
    result = []
    result.push '===== SERVER begin =====\n'
    redisOperation.qget 'server'
    .then (data) ->
      throw data.err if data.err

      server = data.result
      result.push "online: #{server.online}\n" 
      result.push "script_hash: #{server.scriptHash}\n"
      result.push '===== SERVER end =====\n\n'

      result.push '===== NODES begin =====\n'
      redisOperation.qget('nodes')
    .then (data) ->
      return logger.error JSON.stringify(data.err) if data.err
      nodes = data.result

      for socketId, v of nodes
        n = nodes[socketId]
        result.push "***** #{n.name} *****\n"
        result.push "socket.id: #{socketId}\n"
        result.push "script_hash: #{n.scriptHash}\n"
        result.push "working:\n"
        for domain, v of n.working
          # list = n.working[domain]
          # result.push sprintf('   %s: %s\n', domain, list.slice(list.length - 30, list.length))
          result.push "    #{domain}: #{v}\n"
      result.push '===== NODES end =====\n\n'

      result.push '===== DOMAINS begin =====\n'
      redisOperation.qget('domains')
      .then (data) ->
        return logger.error JSON.stringify(data.err) if data.err

        domains = data.result
        redisOperation.qget('worklist')
        .then (data) ->
          return logger.error JSON.stringify(data.err) if data.err

          worklist = data.result
          for domain, v of domains
            total = Object.keys(domains[domain]).length
            remain = total - worklist[domain].length
            result.push sprintf('%s: %d/%d, %.2f\n', domain, remain, total, remain * 100 / total)
          result.push '===== DOMAINS end =====\n\n'

          socket.emit 'result', result.join('')
  .on 'update', (script) ->
    logger.info '***** ADMIN: status *****'
    server = null
    redisOperation.qget 'server'
    .then (data) ->
      throw data.err if data.err

      server = data.result
      server.script = script;
      server.scriptHash = sha1(script);
     
      redisOperation.qupdate 'server', server
    .then (data) ->
      throw data.err if data.err
      logger.info 'server script updated:', server.scriptHash
      redisOperation.qget 'nodes'
    .then (data) ->
      throw data.err if data.err

      nodes = data.result
      for socketId, v of nodes
        logger.info server.scriptHash, '== updated =>', socketId
        allSockets[socketId].emit 'update', script
      socket.emit 'result', 'OK'

    .done()
  .on 'load', (domain, urlConfigsCompressed) ->
    logger.info '***** ADMIN: load *****'
    urlConfigs = JSON.parse compress.uncompress(new Buffer(urlConfigsCompressed))

    redisOperation.qget 'domains'
    .then (data) ->
      throw err if data.err

      domains = data.result

      loadDomainConfig = (domain, domainConfig) ->
        logger.info 'domain', domain, Object.keys(domainConfig).length
        domains[domain] = domainConfig
        now = new Date().getTime()
        for url, v of domainConfig
          urlConfig = domainConfig[url]
          urlConfig.check = now
          urlConfig.validity = 20 * 60 * 1000 if not urlConfig.validity
          urlConfig.priority = 3 if not urlConfig.priority
          urlConfig.state = 'wait'

      if domain
        loadDomainConfig domain, urlConfigs
      else
        for domain, v of urlConfigs
          loadDomainConfig domain, urlConfigs[domain]

      # logger.info '================domains: ', JSON.stringify(domains)
      redisOperation.qupdate 'domains', domains
    .catch (err) ->
      logger.error JSON.stringify(err)
    .done()

    reorder()
    socket.emit 'result', 'OK'
  .on 'unload', (domain) ->
    logger.info '***** ADMIN: unload *****'
    domains = null
    redisOperation.qget 'domains'
    .then (data) ->
      throw data.err if data.err

      domains = data.result
      if domain
        domains[domain] = null
        delete domains[domain]
      else
        domains = {}

      redisOperation.qupdate 'domains', domains
    .then (data) ->
      throw data.err if data.err

      reorder()
      logger.info 'remaining domains:', Object.keys(domains)
      socket.emit 'result', 'OK'

  .on 'refresh', (domain) ->
    logger.info '***** ADMIN: refresh *****'
    now = new Date().getTime()
    redisOperation.qget 'domains'
    .then (data) ->
      throw data.err if data.err

      domains = data.result
      for _domain, v of domains
        continue if domain is _domain
        urlConfigs = domains[_domain]
        for url, v of urlConfigs
          urlConfigs[url].check = now

      reorder()
      socket.emit 'result', 'OK'