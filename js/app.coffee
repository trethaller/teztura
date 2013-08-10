
class Document
  constructor: (@width,@height)->
    @layer = new Layer(@width,@height)

Editor = Backbone.Model.extend({
  toolObject: null
  getToolObject: ()->
    if @get('toolObject') is null
      console.log "Creating brush of type " + @get("tool").description.name
      o = @get('tool').createTool(this)
      @set('toolObject', o)
    return @get('toolObject')
  setToolDirty: ()->
    @set('toolObject', null)
})

editor = new Editor {
  doc: null
  tool: null
  preset: null
  renderer: null
  tiling: true
  targetValue: 1.0
  altkeyDown: false
}

Renderers = [GammaRenderer, NormalRenderer, GradientRenderer]
Tools = [RoundBrush, Picker]

Commands = [
  {
    name: "Fill"
    func: (doc)->
      val = editor.get('targetValue')
      fillLayer doc.layer, (x,y)->
        return val
      refresh()
  },
  {
    name: "Invert"
    func: (doc)->
      buf = doc.layer.getBuffer()
      len = buf.length
      `for(var i=0; i<len; ++i) {
        buf[i] = -buf[i];
      }
      `      
      refresh()
  },
  {
    name: "Flip H"
    func: (doc)->
      buf = doc.layer.getBuffer()
      len = buf.length
      height = doc.layer.height
      width = doc.layer.width
      halfw = Math.floor(doc.layer.width / 2.0)
      maxx = doc.layer.width - 1;
      tmp = 0.0
      `for(var iy=0; iy<height; ++iy) {
        var offset = iy * width
        for(var ix=0; ix<halfw; ++ix) {
          tmp = buf[offset + ix];
          buf[offset + ix] = buf[offset + maxx - ix];
          buf[offset + maxx - ix] = tmp;
        }
      }
      `      
      refresh()
  },
  {
    name: "Flip V"
    func: (doc)->
      buf = doc.layer.getBuffer()
      len = buf.length
      height = doc.layer.height
      width = doc.layer.width
      halfh = Math.floor(doc.layer.width / 2.0)
      maxy = doc.layer.width - 1;
      tmp = 0.0
      `for(var iy=0; iy<halfh; ++iy) {
        for(var ix=0; ix<width; ++ix) {
          tmp = buf[iy*width + ix];
          buf[iy*width + ix] = buf[(maxy - iy)*width + ix];
          buf[(maxy - iy)*width + ix] = tmp;
        }
      }
      `      
      refresh()
  },
]

class DocumentView
  drawing: false
  panning: false
  imageData: null
  context: null
  canvas: null
  backContext: null
  doc: null
  offset: new Vec2(0.0, 0.0)
  scale: 1.0

  constructor: ($container, doc)->
    @doc = doc
    $container.empty()
    $canvas = $('<canvas/>',{'class':''}).attr {width: doc.width, height:doc.height}
    $backCanvas = $('<canvas/>',{'class':''}).attr {width: doc.width, height:doc.height}
    $container.append($backCanvas)

    @backContext = $backCanvas[0].getContext('2d')
    @canvas = $canvas[0] 
    @context = $canvas[0].getContext('2d')
    @imageData = @context.getImageData(0,0,doc.width,doc.height)

    @context.mozImageSmoothingEnabled = false

    self = this

    getCoords = (e)->
      x = e.pageX-$backCanvas.position().left
      y = e.pageY-$backCanvas.position().top
      return new Vec2(x,y)

    getCanvasCoords = (e)->
      v = getCoords(e)
      return self.screenToCanvas(v)

    local = {}

    $backCanvas.mousedown (e)->
      e.preventDefault()
      if e.which is 1
        self.drawing = true
        coords = getCanvasCoords(e)
        editor.getToolObject().beginDraw(coords)
        self.onDraw(coords)

      if e.which is 2
        self.panning = true
        local.panningStart = getCoords(e)
        local.offsetStart = self.offset.clone()

    $container.mouseup (e)->
      e.preventDefault()
      if e.which is 1
        editor.getToolObject().endDraw(getCanvasCoords(e))
        self.drawing = false

      if e.which is 2
        self.panning = false

    $container.mousemove (e)->
      e.preventDefault()
      if self.drawing
        self.onDraw(getCanvasCoords(e))

      if self.panning
        curPos = getCoords(e)
        o = local.offsetStart.add(curPos.sub(local.panningStart))
        #limW = self.doc.width / 3.0
        #limH = self.doc.height / 3.0
        #self.offset.x = Math.min(Math.max(o.x, -limW), limW)
        #self.offset.y = Math.min(Math.max(o.y, -limH), limH)
        self.offset = o
        self.rePaint()
 
  screenToCanvas: (pt)->
    return pt.sub(@offset).scale(1.0/@scale)

  reRender: ()->
    layer = @doc.layer
    editor.get('renderer').renderLayer(layer, this, [new Rect(0,0,@doc.width,@doc.height)])
    @rePaint()

  rePaint: ()->
    ctx = @backContext
    ctx.setTransform(1, 0, 0, 1, 0, 0)
    ctx.translate(@offset.x, @offset.y)
    ctx.scale(@scale, @scale)
    
    if editor.get('tiling')
      ctx.fillStyle = ctx.createPattern(@canvas,"repeat")
      ctx.fillRect(-@offset.x / @scale,-@offset.y / @scale,@canvas.width / @scale, @canvas.height / @scale)
    else
      ctx.drawImage(@canvas, 0, 0)

  onDraw: (pos)->
    self = this

    pressure = getPenPressure()
    dirtyRects = []

    layer = @doc.layer
    tool = editor.getToolObject()

    layerRect = layer.getRect()
    
    r = tool.draw(layer, pos, pressure).round()

    if editor.get('tiling')
      for xoff in [-1,0,1]
        for yoff in [-1,0,1]
          dirtyRects.push(r.offset(new Vec2(xoff * layerRect.width, yoff * layerRect.height)))
    else
      dirtyRects.push(r)

    dirtyRects = dirtyRects
      .map((r)->r.intersect(layerRect))
      .filter((r)->not r.isEmpty())

    if false # Log dirty rects
      totalArea = dirtyRects
        .map((r)-> r.width * r.height)
        .reduce((a,b)-> a+b)
      console.log "#{dirtyRects.length} rects, #{Math.round(Math.sqrt(totalArea))} px²"

    if true
    #setTimeout (()->
      editor.get('renderer').renderLayer(layer, self, dirtyRects)
      self.rePaint()
    #), 0

# ---

getPenPressure = () ->
  plugin = document.getElementById('wtPlugin')
  penAPI = plugin.penAPI
  if penAPI and penAPI.pointerType > 0
    return penAPI.pressure
  return 1.0

# ---


status = (txt)->
  $('#status-bar').text(txt)

view = null


refresh = ()->
  view.reRender()
  view.rePaint()

PropertyView = Backbone.View.extend
  className: "property"

  initialize: () ->
    tool = @model.tool
    prop = @model.prop

    # Label
    $('<span/>').text(prop.name).appendTo(@$el)

    # Slider
    if prop.range?
      step = if prop.type is 'int' then 1 else (prop.range[1]-prop.range[0]) / 100
      $slider = $('<div/>').slider({
        min: prop.range[0]
        max: prop.range[1]
        value: tool.get(prop.id)
        step: step
        change: (evt, ui)->
          tool.set(prop.id, ui.value)
          editor.setToolDirty()
      }).width(200).appendTo(@$el)

      $val = $('<input/>')
        .val(tool.get(prop.id))
        .appendTo(@$el)
        .change (evt)->
          if prop.type is 'int'
            tool.set(prop.id, parseInt($val.val()))
          else
            tool.set(prop.id, parseFloat($val.val()))

      @listenTo @model.tool, "change:#{prop.id}", ()->
        v = tool.get(prop.id)
        $val.val(v)
        $slider.slider("value", v)
        
# --
class PropertyPanel
  views: []
  constructor: (@selector)-> ;
  setTool: (tool)->
    self = this
    @removeViews()
    tool.properties.forEach (prop)->
      v = new PropertyView
        model: {prop, tool}

      $(self.selector).append(v.$el)
      self.views.push(v)

  removeViews: ()->
    @views.forEach (v)->
      v.remove()
    @views = []


toolsProperties = new PropertyPanel '#tools > .properties'

editor.on 'change:tool', ()->
  editor.setToolDirty()
  tool = editor.get('tool')
  toolsProperties.setTool(tool)

editor.on 'change:preset', ->
  p = editor.get('preset')
  editor.set('tool', p.tools[0])

editor.on 'change:altkeyDown', ->
  idx = if editor.get('altkeyDown') then 1 else 0
  p = editor.get('preset')
  editor.set('tool', p.tools[idx])

editor.on 'change:renderer', ()->
  view.reRender()
  view.rePaint()


createToolsButtons = ($container)->
  $container.empty()
  Tools.forEach (b)->
    name = b.description.name
    $btn = $('<button/>').attr({'class':'btn'}).text(name)
    $btn.click (e)->
      editor.set('tool', b)
    $container.append($btn)

createRenderersButtons = ($container)->
  $container.empty()
  Renderers.forEach (r)->
    name = r.description.name
    $btn = $('<button/>').attr({'class':'btn'}).text(name)
    $btn.click (e)->
      editor.set('renderer', r)
    $container.append($btn)

createCommandsButtons = ($container)->
  Commands.forEach (cmd)->
    $btn = $('<button/>').
      attr({'class':'btn'}).
      text(cmd.name).
      appendTo($container)
    $btn.click (e)->
      cmd.func(editor.get('doc'))

createPalette = ($container)->
  $slider = $('<div/>').slider({
    min: -1.0
    max: 1.0
    value: 0
    step: 0.005
    change: (evt, ui)->
      editor.set('targetValue', ui.value)
  }).appendTo($container)

  editor.on 'change:targetValue', ()->
    $slider.slider 
      value: editor.get('targetValue')


loadGradient = (name, url)->
  $canvas = $('<canvas/>').attr {width: 512, height:1}
  ctx = $canvas[0].getContext('2d')
  imageObj = new Image()
  imageObj.onload = ()->
    ctx.drawImage(this, 0, 0);
    imageData = ctx.getImageData(0,0,512,1)
    data = new Uint32Array(imageData.data.buffer)
    GradientRenderer.properties.gradient = {
      lut: data
    }
  imageObj.src = url

# --

_.templateSettings = {
  interpolate : /\{\{(.+?)\}\}/g
};

loadGradient('g1', 'img/gradient-1.png')


$(window).keydown (e)->
  if e.key is 'Control'
    editor.set('altkeyDown', true)

$(window).keyup (e)->
  if e.key is 'Control'
    editor.set('altkeyDown', false)

$(document).ready ()->
  doc = new Document(512, 512)
  fillLayer doc.layer, (x,y)->
    return -1

  view = new DocumentView($('.document-view'), doc)

  createToolsButtons($('#tools > .buttons'))
  createRenderersButtons($('#renderers > .buttons'))
  createPalette($('#palette'))
  createCommandsButtons($('#commands'))
  
  editor.set('doc', doc)
  #editor.set('tool', RoundBrush)
  editor.set('preset', {
    tools: [RoundBrush, Picker]
  })
  editor.set('renderer', GammaRenderer)
  editor.set('targetValue', 0.0)
