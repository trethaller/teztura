
class Document
  constructor: (@width,@height)->
    @layer = new Layer(@width,@height)

Editor = {
  brush: null
  renderer: GammaRenderer
  targetValue: 1.0
}

Editor.brush = RoundBrush.genBrush(Editor)


class DocumentView
  drawing: false
  panning: false
  imageData: null
  context: null
  canvas: null
  backContext: null
  doc: null
  offset: new Vector(0.0, 0.0)
  scale: 1

  constructor: ($container, doc)->
    console.log "DocumentView constructor"

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
      return new Vector(x,y)

    getCanvasCoords = (e)->
      v = getCoords(e)
      return self.screenToCanvas(v)

    local = {}

    $container.mousedown (e)->
      e.preventDefault()
      if e.which is 1
        self.drawing = true
        Editor.brush.beginDraw()
        self.onDraw(getCanvasCoords(e))

      if e.which is 2
        self.panning = true
        local.panningStart = getCoords(e)
        local.offsetStart = self.offset

    $container.mouseup (e)->
      if e.which is 1
        Editor.brush.endDraw()
        self.drawing = false

      if e.which is 2
        self.panning = false

    $container.mousemove (e)->
      if self.drawing
        self.onDraw(getCanvasCoords(e))

      if self.panning
        curPos = getCoords(e)
        self.offset = local.offsetStart.add(curPos.sub(local.panningStart))
        self.transformChanged()
 
  screenToCanvas: (pt)->
    return pt.sub(@offset).scale(1.0/@scale)

  refreshAll: ()->
    layer = @doc.layer
    Editor.renderer.renderLayer(layer, this, [new Rect(0,0,@doc.width,@doc.height)])
    @backContext.drawImage(@canvas, 0, 0)

  transformChanged: ()->
    @backContext.setTransform(1, 0, 0, 1, 0, 0)
    @backContext.translate(@offset.x, @offset.y)
    @backContext.scale(@scale, @scale)
    @backContext.drawImage(@canvas, 0, 0)

  onDraw: (pos)->
    pressure = getPenPressure()
    dirtyRects = []

    layer = @doc.layer
    brush = Editor.brush

    layerRect = layer.getRect()
    rect = brush.draw(layer, pos, pressure).round().intersect(layerRect)
    if not rect.empty()
      dirtyRects.push(rect)

    self = this

    if true
    #setTimeout (()->
      Editor.renderer.renderLayer(layer, self, dirtyRects)
      for rect in dirtyRects
        self.backContext.drawImage(self.canvas,
          rect.x, rect.y, rect.width+1, rect.height+1,
          rect.x, rect.y, rect.width+1, rect.height+1)
    #), 0

# ---

AppCtrl = ($scope)->
  $scope.test = 'lol'

getPenPressure = () ->
  plugin = document.getElementById('wtPlugin')
  penAPI = plugin.penAPI
  if penAPI and penAPI.pointerType > 0
    return penAPI.pressure
  return 1.0

# ---

$(document).ready ()->
  doc = new Document(512, 512)
  fillLayer doc.layer, (x,y)->
    x += 1.0
    y += 1.0
    return (Math.round(x*40) % 2) * 0.1 -
        (Math.round(y*40) % 2) * 0.1

  view = new DocumentView($('.document-view'), doc)
  view.transformChanged()
  view.refreshAll()
