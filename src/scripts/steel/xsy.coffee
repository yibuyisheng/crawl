((urlConfigs, parsers) ->
  sprintf = require("sprintf").sprintf
  $ = require("jQuery")
  configs = {}
  i = 0

  while i++ <= 10
    url = sprintf("%d", i)
    configs[url] =
      priority: i
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
        
  urlConfigs["xsy"] = configs
  parser =
    download: (url) ->
      postBody = "searchFlag=&ifzp=0&bean.pm=&bean.cz=&bean.cd=&bean.ck=&bean.dx=0&bean.hd1=&bean.hd2=&bean.kd1=&bean.kd2=&bean.cd1=&bean.cd2=&bean.zl1=&bean.zl2=&bean.djg1=&bean.djg2=&bean.kbh=&bean.customerIdFlag=&bean.distributionModel=&bean.zyh=&bean.zyflEn=&bean.zyflCh=&orderGg=&orderJg=&orderName=&providerAreaId=010&providerAreaId=010&providerAreaId=010&providerAreaId=010&providerAreaId=009&providerAreaId=010&providerAreaId=010&providerAreaId=010&providerAreaId=010&providerAreaId=010&currPage=%s&totalPage=500&pageSize=100&jumpPage=1"
      $.post "http://www.baosteel-xsy.com/ecp/index/index_queryForLogin.action?url=www.baosteel-xsy.com", sprintf(postBody, url)

    parse: (url, content) ->
      result = []

      now = new Date()
      $trs = $(content).find '#infolist>table.maintab>tr'
      $trs.each (index) ->
        return if $(this).hasClass('even') or index is 0

        $tr = $(this)
        item = 
          from_site: "http://www.baosteel-xsy.com"
          crawl_time: "#{now.getFullYear()}-#{now.getMonth() + 1}-#{now.getDate()} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
          product_name: escapeCharacters $tr.find('td:nth-child(3)').html().split('&nbsp;&nbsp;')[0].split('：')[1].replace(/\s/g, '')
          spec: $tr.find('td:nth-child(3) a font').text().split('：')[1].replace(/\s/g, '')
          shop_sign: escapeCharacters $tr.find('td:nth-child(3)').html().split('&nbsp;&nbsp;')[1].split('：')[1].replace(/\s/g, '')
          weight: parseInt $tr.find('td:nth-child(5)').text().split('：')[1]
          manufacturer: escapeCharacters $tr.find('td:nth-child(4)').html().split('：')[1].split('<br>')[0].replace(/\s/g, '')
          provider_name: '宝钢股份'
          price: parseFloat $tr.find('td:nth-child(7) span').html().replace(/,/g, '')
          pieces: parseInt $tr.find('td:nth-child(5)').text().split('：')[2]
          contact: ''
          region_name: escapeCharacters $tr.find('td:nth-child(4)').html().split('<br>')[1].split('：')[1]
          warehouse_name: escapeCharacters $tr.find('td:nth-child(6)').html().split('<br>')[0].replace(/\s/g, '')
          contact_mobile: ''
          contact_name: ''
          contact_phone: $tr.find('.more-info:eq(1) tr:first-child td').html().split('&nbsp;&nbsp;')[3]
          contact_address: $tr.find('.more-info:eq(1) tr:last-child td').html().split('&nbsp;&nbsp;')[3]

        result.push item

      result

    process: process

  parsers["xsy"] = parser
) urlConfigs, parsers