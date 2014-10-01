((urlConfigs, parsers) ->
  sprintf = require("sprintf").sprintf
  $ = require("jQuery")
  urlConfigs["zhaogang"] = 
    "http://www.zhaogang.com/ajax/mallservice.ashx?method=getgoods":
      priority: 1
      # validity: 3 * 60 * 1000
      validity: 5 * 1000
      delay: 1000 * 60 * 10
      paramsList: [
        {
          self_prod: 'F'
          quality_supplier: 'F'
          order_by: 0
          page_index: 12
          page_size: 25
          stock_type: -1
          is_blocked: -1
          category_name: ''
          factory_name: ''
          material_name: ''
          specification_name: ''
          specification_name2: ''
          warehouse_name: ''
          cate: ''
          keyword: ''
        }
      ]
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
      now = new Date()
      for data in content
        dataJson = JSON.parse data
        for row in dataJson.stocks
          console.log Object.keys(row)
          result.push
            from_site: 'http://www.zhaogang.com'
            crawl_time: "#{now.getFullYear()}-#{now.getMonth() + 1}-#{now.getDate()} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}"
            product_name: row.category_name
            spec: row.specification_name
            shop_sign: row.material_name
            weight: row.piece_weight
            manufacturer: row.factory_name
            provider_name: ''
            price: row.price
            pieces: row.quantity
            contact: ''
            region_name: row.warehouse_city
            warehouse_name: row.warehouse_name
            contact_mobile: ''
            contact_name: ''
            contact_phone: ''
            contact_address: ''

      result

  parsers["zhaogang"] = parser
  return
) urlConfigs, parsers