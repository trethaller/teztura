
createProperties = (target, definitions, changed) ->
  for p in definitions
    pid = '_' + p.id
    target[pid] = p.defaultValue
    target[p.id] = (val)!->
      if val?
        prev = target[pid]
        target[pid] = val
        if changed?
          changed p.id, prev, val
      else
        return target[pid]

export { createProperties }
