((urlConfigs, parsers) ->
  $ = require("jQuery")

  configs = {}
  configs['http://www.banksteel.com/search?bi=&bd=&st=1&kw=&ml=&sp=&br=&ci=0101&cy=&md=&wh=&pr1=&pr2=&ts1=&ts2=&wi1=&wi2=&sort=&pg=1'] =
    priority: 1
    # validity: 3 * 60 * 1000
    validity: 5 * 1000

  urlConfigs["banksteel"] = configs
  parser =
    download: gbkGet

    parse: (url, content) ->
      now = new Date()
      result = []
      $(content).find('.mtable>tr.bg').each (index) ->
        $tr = $ this
        $trNext = $tr.next()

        contact_phone = $trNext.find('td').html().replace('*', '').match(/(电话：|销售热线：|销售电话：)[0-9|-]{12,}/)
        contact_phone = if contact_phone then contact_phone[0].replace(/(电话：|销售热线：|销售电话：)/, '') else ''
        contact_mobile = $trNext.find('td').html().match(/手机：[0-9]{11}/)
        contact_mobile = if contact_mobile then contact_mobile[0].replace(/手机：/, '') else ''

        result.push
          from_site: 'http://www.banksteel.com'
          crawl_time: "#{now.getFullYear()}-#{now.getMonth() + 1}-#{now.getDate()} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
          product_name: escapeCharacters $tr.find('td:first-child a:first-child').html()
          spec: escapeCharacters $tr.find('td:nth-child(2) div').html()
          shop_sign: escapeCharacters $tr.find('td:nth-child(3)').html().replace(/\s/g, '')
          weight: parseFloat $tr.find('td:nth-child(6) a').html().split('/')[1]
          manufacturer: $tr.find('td:nth-child(4)').html()
          provider_name: $tr.find('td:nth-child(8) a').html()
          price: parseFloat $tr.find('td:nth-child(7) b').text()
          pieces: parseInt $tr.find('td:nth-child(6) a').html().split('/')[0]
          contact: ''
          region_name: ''
          warehouse_name: $tr.find('td:nth-child(5) a').attr('title')
          contact_mobile: contact_mobile
          contact_name: ''
          contact_phone: contact_phone
          contact_address: ''

      result

  parsers["banksteel"] = parser
  return
) urlConfigs, parsers