
createProperties = (target, definitions, changed) ->
  target.properties = []
  definitions.forEach (def) ->
    prop = ^^def
    prop.value = ko.observable def.defaultValue

    if changed?
      prop.value.subscribe (val) ->
        changed prop.id, val

    target[prop.id] = prop.value
    target.properties.push prop

export { createProperties }
