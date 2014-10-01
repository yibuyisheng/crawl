((urlConfigs, parsers) ->
  sprintf = require("sprintf").sprintf
  $ = require("jQuery")

  configs = {}
  i = 1

  configs['http://list.sososteel.com/res/topByMemberIds.html?mds=285978;15697;1069;1490297&nums=1;1;1;179&v=2014681041'] =
    priority: 1
    # validity: 3 * 60 * 1000
    validity: 5 * 1000
  configs['http://list.sososteel.com/res/banksteel.html?kw=&ct=&cy=&ml=&sp=&fa=&wh=&pr1=&pr2=&ts1=&ts2=&wi1=&wi2=&sort='] =
    priority: 2
    # validity: 3 * 60 * 1000
    validity: 5 * 1000

  urlConfigs["mysteel"] = configs
  parser =
    download: (url) ->
      deferred = Q.defer()
      request 
        url: url
        encoding: null
        headers: 
          Referer: 'http://list.sososteel.com/res/p--------------------------------1.html'
      , (error, response, body) ->
        deferred.resolve iconv.decode(body, "GBK")

      deferred.promise

    parse: (url, content) ->
      datas = JSON.parse content

      now = new Date()
      result = []
      for data in datas
        result.push
          from_site: 'http://list.sososteel.com'
          crawl_time: "#{now.getFullYear()}-#{now.getMonth() + 1}-#{now.getDate()} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
          product_name: data.sBreedName
          spec: data.sSpecification
          shop_sign: data.sMaterial
          weight: data.sQuantity
          manufacturer: data.sFactory
          provider_name: data.sMemberName
          price: data.sPrice
          pieces: -1
          contact: ''
          region_name: data.sCityName
          warehouse_name: data.sWarehouse
          contact_mobile: data.sMobile
          contact_name: data.sContactorName
          contact_phone: data.sPhone
          contact_address: ''

      result

  parsers["mysteel"] = parser
  return
) urlConfigs, parsers