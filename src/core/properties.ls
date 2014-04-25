
createProperties = (target, definitions, changed) ->
  target.properties = {}
  definitions.forEach (def) ->
    prop = ^^def
    prop.val = def.defaultValue
    prop.set = (val)->
      prev = prop.val
      prop.val = val
      if changed?
        changed prop.id, val, prev
    prop.get = -> prop.val

    target[prop.id] = (val)->
      if val?
        prop.set val
      else
        prop.get!
        
    target.properties[prop.id] = prop

export { createProperties }
