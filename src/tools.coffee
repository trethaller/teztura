
class StepBrush
  drawing: false
  lastpos: null
  accumulator: 0.0
  stepSize: 4.0
  nsteps: 0
  tiling: false

  drawStep: (layer, pos, intensity, rect)->
    fb = layer.getBuffer()
    fb[ Math.floor(pos.x) + Math.floor(pos.y) * layer.width ] = intensity
    rect.extend(pos)

  move: (pos, pressure) ->;
  draw: (layer, pos, pressure) ->
    wpos = if @tiling then pos.wrap(layer.width, layer.height) else pos
    rect = new Rect(wpos.x, wpos.y, 1, 1)
    intensity = pressure
    if @lastpos?
      delt = pos.sub(@lastpos)
      length = delt.length()
      dir = delt.scale(1.0 / length)
      while(@accumulator + @stepSize <= length)
        @accumulator += @stepSize
        pt = @lastpos
          .add(dir.scale(@accumulator))
        if @tiling
          pt = pt.wrap(layer.width, layer.height)
        @drawStep(layer, pt, intensity, rect)
        ++@nsteps
      @accumulator -= length
    else
      @drawStep(layer, wpos, intensity, rect)
      ++@nsteps

    @lastpos = pos
    return rect

  beginDraw: (layer, pos) ->
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
    beginDraw: (layer, pos)->;
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
      id: 'step'
      name: "Step %"
      defaultValue: 10
      range: [0, 100]
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
      defaultValue: 30.0
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
      defaultValue: 0.4
      range: [0.0, 1.0]
      power: 2.0
    }
  ]

  self = new Backbone.Model

  createTool = (env)->
    sb = new StepBrush()

    size = self.get('size')
    sb.stepSize = Math.round(self.get('step') * size / 100.0)
    if sb.stepSize < 1
      sb.stepSize = 1
    sb.tiling = env.get('tiling')

    hardness = Math.pow(self.get('hardness'), 2.0) * 8.0;
    hardnessPlus1 = hardness + 1.0
    func = genBrushFunc {
      args: "intensity, target, h, hp1"
      tiling: env.get('tiling')
      blendExp: BlendModes[self.get('blendMode')]
      brushExp: "var d = Math.min(1.0, Math.max(0.0, (Math.sqrt(x*x + y*y) * hp1 - h)));
                {out} = Math.cos(d * Math.PI) * 0.5 + 0.5;"
    }

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



FlattenBrush = (()->
  description =
    name: 'Flatten'
  properties = [
    {
      id: 'step'
      name: "Step %"
      defaultValue: 10
      range: [0, 100]
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
      defaultValue: 30.0
      range: [1.0, 256.0]
      type: 'int'
    },
    {
      id:'intensity'
      name: "Intensity"
      defaultValue: 0.1
      range: [0.0, 1.0]
      power: 2.0
    }
  ]

  self = new Backbone.Model

  createTool = (env)->
    sb = new StepBrush()
    size = self.get('size')

    sb.stepSize = Math.round(self.get('step') * size / 100.0)
    if sb.stepSize < 1
      sb.stepSize = 1
    sb.tiling = env.get('tiling')

    hardness = Math.pow(self.get('hardness'), 2.0) * 8.0;
    hardnessPlus1 = hardness + 1.0
    func = genBrushFunc {
      args: "intensity, h, normal, det"
      tiling: env.get('tiling')
      brushExp: "var d = Math.min(1.0, Math.max(0.0, (Math.sqrt(x*x + y*y) * (h+1) - h)));
                {out} = Math.cos(d * Math.PI) * 0.5 + 0.5;"
      blendExp: "var tar = (-normal.x * (rect.x + sx) - normal.y * (rect.y + sy) - det) / normal.z;
                {dst} = {dst} * (1 - intensity * {src}) + intensity * tar * {src};"
    }

    sb.drawStep = (layer, pos, intensity, rect)->
      r = new Rect(
        pos.x - size * 0.5,
        pos.y - size * 0.5,
        size, size)

      rad = Math.round(self.get('size') * 0.5 * 0.75)
      self.normal = layer.getNormalAt(pos, rad)
      self.origin = new Vec3(pos.x, pos.y, layer.getAt(pos))
      det = -self.normal.x * self.origin.x - self.normal.y * self.origin.y - self.normal.z * self.origin.z;
      func(r, layer, intensity * self.get('intensity'), hardness, self.normal, det)
      rect.extend(r.round())

    return {
      drawStep: ()-> StepBrush.prototype.drawStep.apply(sb, arguments)
      draw: ()-> StepBrush.prototype.draw.apply(sb, arguments)
      beginDraw: (layer, pos)->
        self.normal = layer.getNormalAt(pos)
        self.origin = new Vec3(pos.x, pos.y, layer.getAt(pos))
        StepBrush.prototype.beginDraw.apply(sb, arguments)
      endDraw: ()-> StepBrush.prototype.endDraw.apply(sb, arguments)
    }

  self.properties = properties
  self.description = description
  self.createTool = createTool

  properties.forEach (p)->
    self.set(p.id, p.defaultValue)
  return self
)()
