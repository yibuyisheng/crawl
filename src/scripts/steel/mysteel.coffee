((urlConfigs, parsers) ->
  sprintf = require("sprintf").sprintf
  $ = require("jQuery")

  configs = {}
  for index in [0..2] by 1
    configs['http://baoge.mysteel.com.cn/resource/index.html?cn=&bn=&sp=&ma=&ct=&fa=&wh=&md=622003&status=1&count=30&pg=' + (index + 1)] =
      priority: 1
      validity: 1 * 1000

  for index in [0..2] by 1
    configs['http://shyhsy.mysteel.com.cn/resource/index.html?cn=&bn=&sp=&ma=&ct=&fa=&wh=&md=2048023&status=1&count=20&pg=' + (index + 1)] =
      priority: 1
      validity: 1 * 1000

  for index in [0..7] by 1
    configs['http://baoze.mysteel.com.cn/resource/index.html?cn=&bn=&sp=&ma=&ct=&fa=&wh=&md=2048023&status=1&count=20&pg=' + (index + 1)] =
      priority: 1
      validity: 1 * 1000

  for index in [0..1] by 1
    configs['http://yuyan.mysteel.com.cn/resource/index.html?cn=&bn=&sp=&ma=&ct=&fa=&wh=&md=2048023&status=1&count=20&pg=' + (index + 1)] =
      priority: 1
      validity: 1 * 1000

  configs['http://baoshunchang.mysteel.com.cn/resource.html'] =
    priority: 1
    validity: 1 * 1000

  for index in [0..2] by 1
    configs['http://shhanyuhe.mysteel.com.cn/resource/index.html?cn=&bn=&sp=&ma=&ct=&fa=&wh=&md=736398&status=1&count=20&pg=' + (index + 1)] =
      priority: 1
      validity: 1 * 1000

  for index in [0..12] by 1
    configs['http://yuande.mysteel.com.cn/resource/index.html?cn=&bn=&sp=&ma=&ct=&fa=&wh=&md=921252&status=1&count=30&pg=' + (index + 1)] =
      priority: 1
      validity: 1 * 1000


  urlConfigs["mysteel"] = configs

  parser =
    download: gbkGet
    parse: (url, content) ->
      result = []

      $trs = $(content).find('tr[onmouseover]')
      len = $trs.length
      for index in [0..(len-1)] by 1
        try
          $tr = $trs.eq index
          now = new Date()

          price = $tr.find('td:nth-child(4)').text()
          weight = $tr.find('td:nth-child(5)').text()
          result.push
            from_site: url.match(/^http:\/\/.+\//)[0]
            crawl_time: "#{now.getFullYear()}-#{now.getMonth() + 1}-#{now.getDate()} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
            product_name: $tr.find('td:nth-child(1) a').text()
            spec: $tr.find('td:nth-child(3)').text()
            shop_sign: $tr.find('td:nth-child(2)').text()
            weight: if parseFloat(weight) then parseFloat(weight) else -1
            manufacturer: $tr.find('td:nth-child(6)').text()
            provider_name: ''
            price: if parseFloat(price) then parseFloat(price) else -1
            pieces: -1
            contact: ''
            region_name: $tr.find('td:nth-child(7)').text()
            warehouse_name: $tr.find('td:nth-child(8)').text()
            contact_mobile: ''
            contact_name: $tr.find('td:nth-child(10)').text()
            contact_phone: $tr.find('td:nth-child(11)').text()
            contact_address: ''

        catch e
          console.log e

      result

  parsers["mysteel"] = parser
  return
) urlConfigs, parsers