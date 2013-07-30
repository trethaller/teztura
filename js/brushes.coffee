
class StepBrush
  drawing: false
  lastpos: null
  accumulator: 0.0
  stepSize: 4.0
  nsteps: 0

  drawStep: (layer, pos, intensity, rect)->
    fb = layer.getBuffer()
    fb[ Math.floor(pos.x) + Math.floor(pos.y) * layer.width ] = intensity
    rect.extend(pos)

  move: (pos, intensity) ->;
  draw: (layer, pos, intensity) ->
    rect = new Rect(pos.x, pos.y, 1, 1)
    if @lastpos?
      delt = pos.sub(@lastpos)
      length = delt.length()
      dir = delt.scale(1.0 / length)
      while(@accumulator + @stepSize <= length)
        @accumulator += @stepSize
        pt = @lastpos.add(dir.scale(@accumulator))
        @drawStep(layer, pt, intensity, rect)
        ++@nsteps
      @accumulator -= length
    else
      @drawStep(layer, pos, intensity, rect)
      ++@nsteps

    @lastpos = pos
    return rect

  beginStroke: () ->
    @drawing = true
    @accumulator = 0
    @nsteps = 0
  endStroke: () ->
    @lastpos = null
    @drawing = false
    console.log("#{@nsteps} steps drawn")

