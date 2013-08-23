
Renderers = null
Tools = null
editor = null
toolsProperties = null


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


    getCoords = (e)=>
      x = e.pageX-$backCanvas.position().left
      y = e.pageY-$backCanvas.position().top
      return new Vec2(x,y)

    getCanvasCoords = (e)=>
      v = getCoords(e)
      return @screenToCanvas(v)

    local = {}

    $backCanvas.mousedown (e)=>
      e.preventDefault()
      if e.which is 1
        @drawing = true
        @actionDirtyRect = null
        coords = getCanvasCoords(e)
        editor.getToolObject().beginDraw(coords)
        @onDraw(coords)

      if e.which is 2
        @panning = true
        local.panningStart = getCoords(e)
        local.offsetStart = @offset.clone()

    $container.mouseup (e)=>
      e.preventDefault()
      if e.which is 1
        editor.getToolObject().endDraw(getCanvasCoords(e))
        @drawing = false
        if @actionDirtyRect?
          doc.afterEdit(@actionDirtyRect)

      if e.which is 2
        @panning = false

    $container.mousemove (e)=>
      e.preventDefault()
      if @drawing
        @onDraw(getCanvasCoords(e))

      if @panning
        curPos = getCoords(e)
        o = local.offsetStart.add(curPos.sub(local.panningStart))
        @offset = o
        @rePaint()
 
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
      dirtyRects.push(r.intersect(layerRect))

    dirtyRects = dirtyRects
      .map((r)->r.intersect(layerRect))
      .filter((r)->not r.isEmpty())

    dirtyRects.forEach (r)=>
      if not @actionDirtyRect?
        @actionDirtyRect = r.clone()
      else
        @actionDirtyRect.extend(r)

    if false # Log dirty rects
      totalArea = dirtyRects
        .map((r)-> r.width * r.height)
        .reduce((a,b)-> a+b)
      console.log "#{dirtyRects.length} rects, #{Math.round(Math.sqrt(totalArea))} px²"

    if true
    #setTimeout (()->
      editor.get('renderer').renderLayer(layer, @, dirtyRects)
      @rePaint()
    #), 0

# ---

class Editor extends Backbone.Model
  defaults: ->
    doc: null
    tool: null
    preset: null
    renderer: null
    tiling: true
    targetValue: 1.0
    altkeyDown: false

  initialize: ->  
    @toolObject = null
    @on 'change:tool', ()->
      @setToolDirty()
      tool = @get('tool')
      toolsProperties.setTool(tool)

    @on 'change:preset', ->
      p = @get('preset')
      @set('tool', p.tools[0])

    @on 'change:altkeyDown', ->
      idx = if @get('altkeyDown') then 1 else 0
      p = @get('preset')
      @set('tool', p.tools[idx])

    @on 'change:renderer', ()->
      @get('view').reRender()
      @get('view').rePaint()

  createDoc: (w,h)->
    doc = new Document(512, 512)
    fillLayer doc.layer, (x,y)->
      return -1

    @set('doc', doc)
    @set('view', new DocumentView($('.document-view'), doc))

  getToolObject: ->
    if @get('toolObject') is null
      console.log "Creating brush of type " + @get("tool").description.name
      o = @get('tool').createTool(this)
      @set('toolObject', o)
    return @get('toolObject')

  setToolDirty: ->
    @set('toolObject', null)

  refresh: ->
    v = @get('view')
    v.reRender()
    v.rePaint()

PropertyView = Backbone.View.extend
  className: "property"

  initialize: () ->
    tool = @model.tool
    prop = @model.prop

    # Label
    $('<span/>').text(prop.name).appendTo(@$el)

    # Slider
    if prop.range?
      power = prop.power or 1.0
      conv = (v)-> Math.pow(v, power)
      invconv = (v)-> Math.pow(v, 1.0 / power)
      
      rmin = invconv(prop.range[0])
      rmax = invconv(prop.range[1])
      step = if prop.type is 'int' then 1 else (rmax-rmin) / 100

      $slider = $('<div/>').slider({
        min: rmin
        max: rmax
        value: invconv(tool.get(prop.id))
        step: step
        change: (evt, ui)->
          tool.set(prop.id, conv(ui.value))
          editor.setToolDirty()
      }).width(200).appendTo(@$el)

      $input = $('<input/>')
        .val(tool.get(prop.id))
        .appendTo(@$el)
        .change (evt)->
          if prop.type is 'int'
            tool.set(prop.id, parseInt($input.val()))
          else
            tool.set(prop.id, parseFloat($input.val()))

      @listenTo @model.tool, "change:#{prop.id}", ()->
        v = tool.get(prop.id)
        $input.val(v)
        $slider.slider("value", invconv(v))
        
# --
class PropertyPanel
  constructor: (@selector)->
    @views = []

  setTool: (tool)->
    @removeViews()
    tool.properties.forEach (prop)=>
      v = new PropertyView
        model: {prop, tool}

      $(@selector).append(v.$el)
      @views.push(v)

  removeViews: ()->
    @views.forEach (v)->
      v.remove()
    @views = []

# ---

getPenPressure = () ->
  plugin = document.getElementById('wtPlugin')
  penAPI = plugin.penAPI
  if penAPI and penAPI.pointerType > 0
    return penAPI.pressure
  return 1.0


status = (txt)->
  $('#status-bar').text(txt)



refresh = ()->
  editor.refresh()




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
    value: editor.get('targetValue')
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


$(window).keydown (e)->
  if e.key is 'Control'
    editor.set('altkeyDown', true)

$(window).keyup (e)->
  if e.key is 'Control'
    editor.set('altkeyDown', false)

  if e.ctrlKey
    switch e.keyCode 
      when 90
        editor.get('doc').undo()
        editor.refresh()
      when 89
        editor.get('doc').redo()
        editor.refresh()

$(document).ready ()->

  loadGradient('g1', 'img/gradient-1.png')

  Renderers = [GammaRenderer, NormalRenderer, GradientRenderer]
  Tools = [RoundBrush, Picker]

  toolsProperties = new PropertyPanel '#tools > .properties'
  editor = new Editor()
  editor.createDoc(512, 512)
  

  createToolsButtons($('#tools > .buttons'))
  createRenderersButtons($('#renderers > .buttons'))
  createPalette($('#palette'))
  createCommandsButtons($('#commands'))
  
  editor.set('preset', {
    tools: [RoundBrush, Picker]
  })
  editor.set('renderer', GammaRenderer)
