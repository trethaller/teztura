
$mainCanvas = $('#canvas')
width = $mainCanvas.width()
height = $mainCanvas.height()



drawing = false
gamma = 1.0
layer = new Layer(width, height)
offset = new Vector(100, 50)
scale = 10

brush = new TestBrush1()
brush.stepSize = 1

getMainContext = () ->
  return $mainCanvas[0].getContext('2d')

getPenPressure = () ->
  plugin = document.getElementById('wtPlugin')
  penAPI = plugin.penAPI
  if penAPI and penAPI.pointerType > 0
    return penAPI.pressure
  return 1.0

screenToCanvas = (pt)->
  return pt.sub(offset).scale(1.0/scale)

onDraw = (e) ->
  brushX = e.pageX-$mainCanvas.position().left
  brushY = e.pageY-$mainCanvas.position().top
  pos = screenToCanvas(new Vector(brushX, brushY))

  pressure = getPenPressure()
  brushRects = []
  layerRect = layer.getRect()

  rect = brush.draw(layer, pos, pressure).round().intersect(layerRect)
  if not rect.empty()
    brushRects.push(rect)

  #setTimeout(()->
  if true
    drawLayer(layer,brushRects, gamma)
    for rect in brushRects
      getMainContext().drawImage(layer.canvas,
        rect.x, rect.y, rect.width+1, rect.height+1,
        rect.x, rect.y, rect.width+1, rect.height+1)
  #,0)


changeGamma = (value) ->
  gamma = value
  refresh()

refresh = () ->
  drawLayer(layer,[new Rect(0,0,width,height)], gamma)
  getMainContext().drawImage(layer.canvas, 0, 0)

# ---

$mainCanvas.mouseup (e) ->
  drawing = false
  brush.endStroke()
$mainCanvas.mousedown (e) ->
  drawing = true
  brush.beginStroke()
  onDraw(e)
$mainCanvas.mousemove (e) ->
  if drawing
    onDraw(e)

getMainContext().setTransform(1, 0, 0, 1, 0, 0)
getMainContext().translate(offset.x, offset.y)    
getMainContext().scale(scale, scale)
getMainContext().mozImageSmoothingEnabled = false

$('#gammaSlider').slider(
  min: 0
  max: 4
  step: 0.01
  value: gamma
  change: (evt, ui) ->
    changeGamma ui.value
)

# ---

fillLayer layer, (x,y) ->
  return -0.2

refresh()

fillLayer layer, (x,y) ->
  return -1


