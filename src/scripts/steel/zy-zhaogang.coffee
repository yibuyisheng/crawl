((urlConfigs, parsers) ->
  sprintf = require("sprintf").sprintf
  $ = require("jQuery")
  configs = {}
  urlConfigs["zy.zhaogang"] = 
    "http://zy.zhaogang.com/spot/":
      priority: 1
      # validity: 3 * 60 * 1000
      validity: 5 * 1000
      # 爬取时间为每天早上9点到晚上9点
      duration: 
        startHours: 9
        startMinutes: 0
        startSeconds: 0
        endHours: 21
        endMinutes: 0
        endSeconds: 0

  parser =
    download: httpGet
    parse: (url, content) ->
      result = []
      $doc = $(content)
      $doc.find(".table tbody tr[show]").each ->
        now = new Date()
        $show = $doc.find($(this).attr('show'))
        weightText = $(this).find('td:nth-child(6)').text()
        priceText = $(this).find('td:nth-child(7)').text()

        spanText = $show.find('span:nth-child(3)').text().split('：')[1]
        contact_mobile = if spanText and spanText.match(/1[0-9]{10}/) then spanText.match(/1[0-9]{10}/)[0] else ''
        contact_phone = if spanText then spanText.replace(contact_mobile, '').replace(/\s/g, '') else ''

        contact_address = $show.find('span:nth-child(4)').html().split('：')[1]
        contact_address = escapeCharacters contact_address if contact_address

        contact_name = $show.find('span:nth-child(2)').html().split('：')[1]
        contact_name = escapeCharacters contact_name if contact_name

        obj =
          from_site: "http://zy.zhaogang.com"
          crawl_time: "#{now.getFullYear()}-#{now.getMonth() + 1}-#{now.getDate()} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
          product_name: escapeCharacters $(this).find('td:nth-child(1) .search-a').html().replace(/\s/g, '')
          spec: escapeCharacters $(this).find('td:nth-child(2) a').html().replace(/\s/g, '')
          shop_sign: escapeCharacters $(this).find('td:nth-child(3) a').html().replace(/\s/g, '')
          weight: if parseInt weightText then parseInt weightText else -1
          manufacturer: escapeCharacters $(this).find('td:nth-child(4) a').html().replace(/\s/g, '')
          provider_name: escapeCharacters $(this).find('td:nth-child(8)').html().replace(/\s/g, '')
          price: if parseInt priceText then parseInt priceText else -1
          pieces: -1
          contact: $show.find('span:nth-child(2), span:nth-child(3), span:nth-child(4)').text()
          region_name: ''
          warehouse_name: escapeCharacters $(this).find('td:nth-child(5)').html().replace(/\s/g, '')
          contact_mobile: contact_mobile
          contact_name: contact_name
          contact_phone: contact_phone
          contact_address: contact_address

        result.push obj

      result

  parsers["zy.zhaogang"] = parser
  return
) urlConfigs, parsers