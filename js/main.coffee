
$mainCanvas = $('#canvas')
width = $mainCanvas.width()
height = $mainCanvas.height()



drawing = false
gamma = 1.0
layer = new Layer(width, height)
offset = new Vector(50, 30)

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

onDraw = (e) ->
  brushX = e.pageX-$mainCanvas.position().left-offset.x;
  brushY = e.pageY-$mainCanvas.position().top-offset.y;

  pressure = getPenPressure()
  brushRects = []

  pos = new Vector(brushX, brushY)
  rect = brush.draw(layer, pos, pressure)
  brushRects.push(rect.round())

  setTimeout(()->
    drawLayer(layer,brushRects, gamma)
    for rect in brushRects
      getMainContext().drawImage(layer.canvas,
        rect.x, rect.y, rect.width, rect.height,
        offset.x + rect.x,
        offset.y + rect.y,
        rect.width, rect.height)
  ,0)


changeGamma = (value) ->
  gamma = value
  refresh()

refresh = () ->
  drawLayer(layer,[new Rect(0,0,width,height)], gamma)
  getMainContext().drawImage(layer.canvas, offset.x, offset.y)

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
  #return Math.sin(x * y * 10)
  return -1

refresh()

