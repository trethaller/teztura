
createProperties = (definitions) ->
  {[p.id, p.defaultValue] for p in definitions}  

export { createProperties }
