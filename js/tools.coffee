
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

  move: (pos, pressure) ->;
  draw: (layer, pos, pressure) ->
    rect = new Rect(pos.x, pos.y, 1, 1)
    intensity = pressure
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

BlendModes = 
  add:        "{dst} += {src} * intensity"
  sub:        "{dst} -= {src} * intensity"
  multiply:   "{dst} *= 1 + {src} * intensity"
  blend:      "{dst} = {dst} * (1 - intensity * {src}) + intensity * target * {src}"


Picker = (()->
  description:
    name: 'Picker'

  properties: []
  
  createTool: (env)->
    beginDraw: (pos)->;
    endDraw: (pos)->;
    move: ()->;
    draw: (layer, pos, intensity) ->
      env.set('targetValue', layer.getAt(pos))
      return Rect.Empty
)()


Flatten = (()->
  description:
    name: 'Flatten'

  properties: []
  
  createTool: (env)->
    beginDraw: (pos)->;
    endDraw: (pos)->;
    move: ()->;
    draw: (layer, pos, intensity) ->
      env.set('targetValue', layer.getAt(pos))
      return Rect.Empty
)()


RoundBrush = (()->
  description =
    name: 'Round'
  properties = [
    {
      id: 'stepSize'
      name: "Step size"
      defaultValue: 2
      range: [1, 10]
      type: 'int'
    },
    {
      id: 'hardness'
      name: "Hardness"
      defaultValue: 0.2
      range: [0.0, 1.0]
    },
    {
      id: 'size'
      name: "Size"
      defaultValue: 16.0
      range: [1.0, 256.0]
      type: 'int'
    },
    {
      id: 'blendMode'
      name: "Blend mode"
      defaultValue: "blend"
      choices: ["blend", "add", "sub", "multiply"]
    },
    {
      id:'intensity'
      name: "Intensity"
      defaultValue: 1.0
      range: [0.0, 1.0]
    }
  ]

  self = new Backbone.Model

  createTool = (env)->
    sb = new StepBrush()
    sb.stepSize = self.get('stepSize')
    size = self.get('size')

    hardness = Math.pow(self.get('hardness'), 2.0) * 8.0;
    hardnessPlus1 = hardness + 1.0
    func = genBrushFunc("intensity, target, h, hp1", 
      "var d = Math.min(1.0, Math.max(0.0, (Math.sqrt(x*x + y*y) * hp1 - h)));
      {out} = Math.cos(d * Math.PI) * 0.5 + 0.5;",
      BlendModes[self.get('blendMode')])

    sb.drawStep = (layer, pos, intensity, rect)->
      r = new Rect(
        pos.x - size * 0.5,
        pos.y - size * 0.5,
        size, size)

      func(r, layer, intensity * self.get('intensity'), env.get('targetValue'), hardness, hardnessPlus1)
      rect.extend(r.round())
    return sb

  self.properties = properties
  self.description = description
  self.createTool = createTool

  properties.forEach (p)->
    self.set(p.id, p.defaultValue)
  return self
)();
