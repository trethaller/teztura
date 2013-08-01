

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

BlendModes = 
  add: [
    genBlendFunc("intensity", "{dst} += {src} * intensity"),
    genBlendFunc("intensity", "{dst} -= {src} * intensity"),
  ]

  blendTarget: [
    (() ->
      func = genBlendFunc("intensity, target", "{dst} = {dst} * (1 - intensity * {src}) + target * {src}");
      return (pos, srcFb, dstFb, intensity, target)->
        inttarget = intensity * target
        func(pos, srcFb, dstFb, intensity, inttarget)
    )()
  ]


getBrush = ()->
  brush = new StepBrush()
  brush.stepSize = 4

  brushLayer = new Layer(32,32)

  fillLayer brushLayer, getRoundBrushFunc(0.8)
  bfunc = BlendModes['blendTarget'][0]

  target = 1.0

  brush.drawStep = (layer, pos, intensity, rect)->
    r = new Rect(
      pos.x - brushLayer.width * 0.5,
      pos.y - brushLayer.height * 0.5,
      brushLayer.width,
      brushLayer.height).round()

    bfunc(r.topLeft(), brushLayer, layer, intensity*0.1, target)
    rect.extend(r)

  return brush


Editor = {
  brush: getBrush(),
  renderer: GammaRenderer
}

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
        Editor.brush.beginStroke()
        self.onDraw(getCanvasCoords(e))

      if e.which is 2
        self.panning = true
        local.panningStart = getCoords(e)
        local.offsetStart = self.offset

    $container.mouseup (e)->
      if e.which is 1
        Editor.brush.endStroke()
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
  view.refreshAll()
