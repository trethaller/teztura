Rect = require '../core/rect'

# `stepFunc`: (layer, pos, pressure, rect)
createStepTool = (options, stepFunc)->
  step    = options.step or 4.0
  tiling  = options.tiling or false
  lastpos = null
  accumulator = 0.0

  draw = (layer, pos, pressure) ->
    const wpos = if tiling then pos.wrap(layer.width, layer.height) else pos.clone!
    const rect = new Rect(wpos.x, wpos.y, 1, 1)
    if lastpos?
      delt = pos.sub lastpos
      length = delt.length()
      dir = delt.scale(1.0 / length)
      while accumulator + step <= length
        accumulator += step
        pt = lastpos.add(dir.scale(accumulator))
        if tiling
          pt := pt.wrap(layer.width, layer.height)
        stepFunc layer, pt, pressure, rect
      accumulator -= length
    else
      stepFunc layer, wpos, pressure, rect

    lastpos := pos.clone!
    return rect

  beginDraw = (layer, pos) !->
    accumulator := 0

  endDraw = (pos) !->
    lastpos := null

  {draw, beginDraw, endDraw}

export { createStepTool }