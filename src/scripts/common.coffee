Q = require "q"
iconv = require "iconv-lite"
http = require "http"
request = require 'request'

parsers = {}
urlConfigs = {}
worker = (domain, url, urlConfig, crawlResult) ->
  unless parsers[domain]
    return crawlResult "不认识的域名"
  parser = parsers[domain]
  
  if urlConfig and urlConfig.paramsList
    crawlData = []

    check = (paramsList) ->
      # 检查是否抓取完成
      for params in urlConfig.paramsList
        return false if not params.crawlComplete
      true

    for params, i in urlConfig.paramsList
      # 每个请求之间间隔时间是urlConfig.delay ms
      ((params, i) ->
        setTimeout ->

          parser.download url, params
          .then (data) ->
            if not data.error and data.response.statusCode is 200
              params.crawlComplete = 
                statusCode: 200
              crawlData.push data.body
            else
              params.crawlComplete = 
                statusCode data.response.statusCode

            if check urlConfig.paramsList
              console.log '======================crawlData:', crawlData.length
              crawlResult null, domain, url, parser.parse(url, crawlData)

        , urlConfig.delay * i
      )(params, i)
  else
    parser.download(url).then((content) ->
      try
        crawlResult null, domain, url, parser.parse(url, content)
        # logger 'info', JSON.stringify(parser.parse(url, content))
      catch e
        crawlResult e, domain, url
        # logger 'error', JSON.stringify(e)
    ).fail (err) ->
      crawlResult err, domain, url

generateUrlConfig = (domain) ->
  (if domain then urlConfigs[domain] else urlConfigs)

gbkGet = (url) ->
  deffered = Q.defer()
  http.get(url).on("response", (res) ->
    content = ""
    res.on("data", (trunk) ->
      content += iconv.decode(trunk, "GBK")
      return
    ).on "end", ->
      deffered.resolve content
      return

    return
  ).on "error", (err) ->
    deffered.reject err
    return

  deffered.promise

httpGet = (url) ->
  deffered = Q.defer()
  http.get(url).on("response", (res) ->
    content = ""
    res.on("data", (trunk) ->
      content += trunk.toString()
      return
    ).on "end", ->
      deffered.resolve content
      return

    return
  ).on "error", (err) ->
    deffered.reject err
    return

  deffered.promise


httpPost = (url, params) ->
  deferred = Q.defer()
  request.post url, 
    form: params, 
    (error, response, body) ->
      deferred.resolve 
        error: error
        response: response
        body: body
  
  deferred.promise


hexString = (hexStr) -> 
  bRet = []
  for h, index in hexStr
    if parseInt(h) is 0 and index % 2 is 0
      continue
    else
      bRet[index] = Number(h.charCodeAt(0)).toString 16
  "\\u#{bRet.join '\\u'}"

isMobile = (src) ->
  /^1[0-9]{10}$/.test String(src)

# 替换掉类似于&nbsp;等特殊字符，防止存到数据库中的字符串乱码
escapeCharacters = (src) ->
  String(src).replace /(&[a-z|A-Z];)|(\n)|(\r)|(\t)/g, ''