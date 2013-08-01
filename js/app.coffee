

class Document
  constructor: (@width,@height)->
    @layer = new Layer(@width,@height)


GammaRenderer = (()->
  properties = 
    gamma: 1.0

  `function renderLayer (layer, view, rects) {
    var width = layer.width;
    var height = layer.height;
    var imgData = view.imageData.data;
    var fb = layer.getBuffer();
    var gamma = properties.gamma;
    for(var i in rects) {
      var r = rects[i];
      var minX = r.x;
      var minY = r.y;
      var maxX = minX + r.width;
      var maxY = minY + r.height;
      for(var iy=minY; iy<=maxY; ++iy) {
        var offset = iy * width;
        for(var ix=minX; ix<=maxX; ++ix) {
          var fval = fb[offset + ix];
          var val = Math.pow((fval + 1.0) * 0.5, gamma) * 255.0;
          var i = (offset + ix) << 2;
          imgData[i] = val;
          imgData[++i] = val;
          imgData[++i] = val;
          imgData[++i] = 0xff;
        }
      }
      view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);
    }
  }`

  return {properties, renderLayer}
)();


getBrush = ()->
  brush = new StepBrush()
  brush.stepSize = 4

  brushLayer = new Layer(32,32)

  fillLayer brushLayer, getRoundBrushFunc(0.8)
  bfunc = genBlendFunc("intensity", "{dst} += {src} * intensity")


  brush.drawStep = (layer, pos, intensity, rect)->
    r = new Rect(
      pos.x - brushLayer.width * 0.5,
      pos.y - brushLayer.height * 0.5,
      brushLayer.width,
      brushLayer.height).round()

    bfunc(r.topLeft(), brushLayer, layer, intensity*0.1)
    rect.extend(r)

  return brush


Editor = {
  brush: getBrush(),
  renderer: GammaRenderer
}

class DocumentView
  drawing: false
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
      v = new Vector(x,y)
      return self.screenToCanvas(v)

    $container.mousedown (e)->
      e.preventDefault()
      if e.which is 1
        self.startDrawing(getCoords(e))
    
    $container.mouseup (e)->
      if e.which is 1
        self.stopDrawing()

    $container.mousemove (e)->
      if e.which is 1
        self.mouseMove(getCoords(e))
 
  screenToCanvas: (pt)->
    return pt.sub(@offset).scale(1.0/@scale)

  stopDrawing: ()->
    @drawing = false
    Editor.brush.endStroke()

  startDrawing: (pos)->
    @drawing = true
    Editor.brush.beginStroke()
    @onDraw(pos)

  mouseMove: (pos) ->
    if @drawing
      @onDraw(pos)

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

    Editor.renderer.renderLayer(layer, this, dirtyRects)
    for rect in dirtyRects
      @backContext.drawImage(@canvas,
        rect.x, rect.y, rect.width+1, rect.height+1,
        rect.x, rect.y, rect.width+1, rect.height+1)

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
  view = new DocumentView($('.document-view'), doc)
  view.transformChanged()
