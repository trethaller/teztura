{event} = require '../core/utils'

createProperties = (target, definitions) ->
  target.properties = []
  target.propertyChanged = event!

  definitions.forEach (def) ->
    prop = ^^def
    prop.value = ko.observable def.defaultValue

    prop.value.subscribe (val) ->
      target.propertyChanged prop.id, val

    target[prop.id] = prop.value
    target.properties.push prop

export { createProperties }
