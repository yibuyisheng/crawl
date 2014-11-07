((urlConfigs, parsers) ->
  sprintf = require("sprintf").sprintf
  $ = require("jQuery")

  # 构造paramsList
  paramsList = []
  for index in [0..1488] by 1
    paramsList.push
      'i0-0-prodtypedesc': ''
      'i0-0-spec': ''
      'i0-0-shopsign': ''
      'offset': index * 15
      'limit': 15
      'r-count': 16580
      'jumppage': ''

  urlConfigs["ansteel"] = 
    "http://www.ansteel.net.cn/spot/DispatchAction.do?efFormEname=BP004_2&methodName=AnnounceList_xhzy&serviceName=BP01":
      priority: 1
      # validity: 3 * 60 * 1000
      validity: 5 * 60 * 1000
      delay: 1000
      paramsList: paramsList
      # 爬取时间为每天早上9点到晚上9点
      duration: 
        startHours: 9
        startMinutes: 0
        startSeconds: 0
        endHours: 21
        endMinutes: 0
        endSeconds: 0

  parser =
    download: httpPost
    parse: (url, content) ->
      result = []

      $trs = $(content[0]).find('table.ziyuan tr')
      len = $trs.length
      for index in [1..(len-1)] by 1
        try
          $tr = $trs.eq index
          now = new Date()
          result.push
            from_site: 'http://www.ansteel.net.cn/'
            crawl_time: "#{now.getFullYear()}-#{now.getMonth() + 1}-#{now.getDate()} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
            product_name: $tr.find('td:nth-child(1)').text().split('-')[0]
            spec: $tr.find('td:nth-child(2)').text()
            shop_sign: $tr.find('td:nth-child(3)').text()
            weight: $tr.find('td:nth-child(4)').text()
            # manufacturer: $tr.find('td:nth-child(5)').text()
            manufacturer: '鞍钢'
            provider_name: ''
            price: -1
            pieces: -1
            contact: ''
            region_name: ''
            warehouse_name: ''
            contact_mobile: ''
            contact_name: ''
            contact_phone: ''
            contact_address: ''
        catch e
          console.log e

      result

  parsers["ansteel"] = parser
  return
) urlConfigs, parsers
