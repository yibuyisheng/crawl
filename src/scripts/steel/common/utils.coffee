group = (item) ->
  spec = utils.analyzeSpec(item.spec)
  tags = utils.analyzeTags(item.model + item.trademark + item.producer)
  item.extended = tags.join(" ")
  item.width = spec.width
  item.thick = spec.thick
  item.group_hash = "group_" + sha1(item.extended + spec.width + spec.height)
  
  #item.json = JSON.stringify(item);
  item.json = JSON.stringify(item).replace(/(\\r\\n|\\n|\\r|\\t)/g, " ") # replace line break for safety purpose
  return
process = (item) ->
  s1 = item.model + item.trademark + item.spec + item.producer + item.warehouse + item.store_raw
  h1 = "id_" + sha1(s1)
  s2 = s1 + item.source_raw + item.price_raw + item.weight_raw + item.cell_raw
  h2 = "full_" + sha1(s2)
  item.time = new Date().getTime()
  item.price_float = utils.numberOnly(item.price_raw, true)
  item.weight_float = utils.numberOnly(item.weight_raw)
  item.cell_uint = utils.cellOnly(item.cell_raw)
  item.id_hash = h1
  item.full_hash = h2
  group item
  item
sha1 = require("sha1")
max = 9999999.0
utils =
  numberOnly: (originString, price) ->
    return (if price then max else 0)  unless originString
    result = originString.replace(/[^0-9.]+/g, "")
    return max  unless result
    result = parseFloat(result)
    (if price and result < 2000 then max else result)

  cellOnly: (originString) ->
    return ""  unless originString
    result = originString.match(/1[3-9][0-9]{9}/)
    (if result then parseInt(result[0]) else 0)

  analyzeSpec: (spec) ->
    unless spec
      return (
        width: 0
        thick: 0
      )
    result = spec.replace(/[^0-9.]+/g, " ")
    parts = result.trim().split(" ")
    width: (if parts.length > 0 and parseFloat(parts[0]) then parseFloat(parts[0]) else 0)
    thick: (if parts.length > 1 and parseFloat(parts[1]) then parseFloat(parts[1]) else 0)

  analyzeTags: (tagString) ->
    matchList = []
    TAGS.forEach (tagGroup) ->
      hit = false
      tagGroup.forEach (tag) ->
        hit = true  if tagString.match(tag)
        return

      matchList = matchList.concat(tagGroup)  if hit
      return

    matchList