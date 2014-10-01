((urlConfigs, parsers) ->
  sprintf = require("sprintf").sprintf
  $ = require("jQuery")
  configs = {}
  urlConfigs["opsteel"] = "http://www.opsteel.cn/resource/":
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
    download: gbkGet
    parse: (url, content) ->
      result = []
      $doc = $(content)
      $doc.find("table tbody tr").each ->
        now = new Date()
        weightText = $(this).find("td:nth-child(7)>p:first-child").text()
        priceText = $(this).find("td.nth-child(6)").text()
        piecesText = $(this).find("td:nth-child(7) span").text()

        text = $(this).find("td:nth-child(10) dd p:nth-child(2) .item2").html()
        contact_mobile = if text and text.split(',&nbsp;').length > 1 then text.split(",&nbsp;")[1] else ''
        contact_phone = if text then text.split(',&nbsp;')[0] else ''

        obj =
          from_site: "http://www.opsteel.cn"
          crawl_time: "" + (now.getFullYear()) + "-" + (now.getMonth() + 1) + "-" + (now.getDate()) + " " + (now.getHours()) + ":" + (now.getMinutes()) + ":" + (now.getSeconds())
          product_name: $(this).find("td:nth-child(2)>p:first-child").text()
          spec: $(this).find("td:nth-child(3)").text()
          shop_sign: $(this).find("td:nth-child(4)").text().replace("合格", "")
          weight: (if not parseInt(weightText) then -1 else parseInt(weightText))
          manufacturer: $(this).find("td:nth-child(5)").text()
          provider_name: $(this).find("td:nth-child(10) a.comp-name").text()
          price: (if not parseInt(priceText) then -1 else parseInt(priceText))
          pieces: (if parseInt(piecesText) then parseInt(piecesText) else -1)
          contact: $(this).find("td:nth-child(10) .comp-info>dd").text().replace(/\t/g, "")
          region_name: $(this).find("td:nth-child(8)>p:first-child").text()
          warehouse_name: $(this).find("td:nth-child(8)>p:nth-child(2)").text()
          contact_mobile: contact_mobile
          contact_name: $(this).find("td:nth-child(10) dd p:first-child .item2").html()
          contact_phone: contact_phone
          contact_address: $(this).find("td:nth-child(10) .comp-info>dd .addr").text()

        result.push obj

      result

  parsers["opsteel"] = parser
  return
) urlConfigs, parsers