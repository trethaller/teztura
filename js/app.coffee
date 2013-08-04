
class Document
  constructor: (@width,@height)->
    @layer = new Layer(@width,@height)

Editor = {
  brush: null
  tiling: true
  #renderer: GammaRenderer
  renderer: NormalRenderer
  targetValue: 1.0
}

Renderers = [GammaRenderer, NormalRenderer]
Tools = [RoundBrush, Picker]
Editor.tool = RoundBrush.createTool(Editor)


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

    $container.mousedown (e)->
      e.preventDefault()
      if e.which is 1
        self.drawing = true
        coords = getCanvasCoords(e)
        Editor.tool.beginDraw(coords)
        self.onDraw(coords)

      if e.which is 2
        self.panning = true
        local.panningStart = getCoords(e)
        local.offsetStart = self.offset.clone()

    $container.mouseup (e)->
      if e.which is 1
        Editor.tool.endDraw(getCanvasCoords(e))
        self.drawing = false

      if e.which is 2
        self.panning = false

    $container.mousemove (e)->
      if self.drawing
        self.onDraw(getCanvasCoords(e))

      if self.panning
        curPos = getCoords(e)
        o = local.offsetStart.add(curPos.sub(local.panningStart))
        lim = 200.0
        self.offset.x = Math.min(Math.max(o.x, -lim), lim)
        self.offset.y = Math.min(Math.max(o.y, -lim), lim)
        self.rePaint()
 
  screenToCanvas: (pt)->
    return pt.sub(@offset).scale(1.0/@scale)

  reRender: ()->
    layer = @doc.layer
    Editor.renderer.renderLayer(layer, this, [new Rect(0,0,@doc.width,@doc.height)])
    @rePaint()

  rePaint: ()->
    ctx = @backContext
    ctx.setTransform(1, 0, 0, 1, 0, 0)
    ctx.translate(@offset.x, @offset.y)
    ctx.scale(@scale, @scale)
    
    if Editor.tiling
      ctx.fillStyle = ctx.createPattern(@canvas,"repeat")
      ctx.fillRect(-@offset.x / @scale,-@offset.y / @scale,@canvas.width / @scale, @canvas.height / @scale)
    else
      ctx.drawImage(@canvas, 0, 0)

  onDraw: (pos)->
    self = this

    pressure = getPenPressure()
    dirtyRects = []

    layer = @doc.layer
    brush = Editor.tool

    layerRect = layer.getRect()
    
    r = brush.draw(layer, pos, pressure).round()

    if Editor.tiling
      for xoff in [-1,0,1]
        for yoff in [-1,0,1]
          dirtyRects.push(r.offset(new Vec2(xoff * layerRect.width, yoff * layerRect.height)))
    else
      dirtyRects.push(r)

    dirtyRects = dirtyRects
      .map((r)->r.intersect(layerRect))
      .filter((r)->not r.isEmpty())

    if true
    #setTimeout (()->
      Editor.renderer.renderLayer(layer, self, dirtyRects)
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

createToolsUI = ($container)->
  $container.empty()
  Tools.forEach (b)->
    name = b.description.name
    $btn = $('<button/>').attr({'class':'btn'}).text(name)
    $btn.click (e)->
      Editor.tool = b.createTool(Editor)
      status("Active brush set to #{name}")
    $container.append($btn)

createRenderersUI = ($container)->
  $container.empty()
  Renderers.forEach (r)->
    name = r.description.name
    $btn = $('<button/>').attr({'class':'btn'}).text(name)
    $btn.click (e)->
      Editor.renderer = r
      view.reRender()
      view.rePaint()
      status("Renderer set to #{name}")
    $container.append($btn)

$(document).ready ()->
  doc = new Document(512, 512)
  fillLayer doc.layer, (x,y)->
    x += 1.0
    y += 1.0
    return (Math.round(x*40) % 2) * 0.1 -
        (Math.round(y*40) % 2) * 0.1

  createToolsUI($('#tools'))
  createRenderersUI($('#renderers'))

  view = new DocumentView($('.document-view'), doc)
  view.reRender()
  view.rePaint()
