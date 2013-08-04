
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

  beginDraw: (pos) ->
    @drawing = true
    @accumulator = 0
    @nsteps = 0
  endDraw: (pos) ->
    @lastpos = null
    @drawing = false
    console.log("#{@nsteps} steps drawn")


BlendModes = 
  add:        "{dst} += {src} * intensity"
  sub:        "{dst} -= {src} * intensity"
  multiply:   "{dst} *= 1 + {src} * intensity"
  blend:      "{dst} = {dst} * (1 - intensity * {src}) + intensity * target * {src}"


Picker = (()->
  description:
    name: 'Picker'

  properties: {}
  
  createTool: (env)->
    beginDraw: (pos)->;
    endDraw: (pos)->;
    move: ()->;
    draw: (layer, pos, intensity) ->
      env.targetValue = layer.getAt(pos)
      return Rect.Empty
)()


RoundBrush = (()->
  description =
    name: 'Round'
  properties = {
    stepSize:
      name: "Step size"
      value: 4
      range: [1, 20]
    
    hardness: 
      name: "Hardness"
      value: 0.0
      range: [0.0, 10.0]

    size:
      name: "Size"
      value: 40.0
      range: [1.0, 256.0]

    blendMode: 
      name: "Blend mode"
      value: "blend"
      choices: ["blend", "add", "sub", "multiply"]
    
    intensity: 
      name: "Intensity"
      value: 0.1
      range: [0.0, 1.0]
  }  

  createTool = (env)->
    sb = new StepBrush()
    sb.stepSize = properties.stepSize.value
    rad = properties.size.value

    hardness = properties.hardness.value
    hardnessPlus1 = hardness + 1.0
    func = genBrushFunc("intensity, target, h, hp1", 
      "var d = Math.min(1.0, Math.max(0.0, (Math.sqrt(x*x + y*y) * hp1 - h)));
      {out} = Math.cos(d * Math.PI) * 0.5 + 0.5;",
      BlendModes[properties.blendMode.value])

    sb.drawStep = (layer, pos, intensity, rect)->
      r = new Rect(
        pos.x - rad * 0.5,
        pos.y - rad * 0.5,
        rad,
        rad).round()

      func(r, layer, intensity * properties.intensity.value, env.targetValue, hardness, hardnessPlus1)
      rect.extend(r)
    return sb

  return {description, properties, createTool}
)();
