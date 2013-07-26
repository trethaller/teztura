
$mainCanvas = $('#canvas')
width = $mainCanvas.width()
height = $mainCanvas.height()



drawing = false
gamma = 1.0
layer = new Layer(width, height)
offset = new Vector(50, 30)


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
  brushW = 30
  brushH = 20

  pressure = getPenPressure()
  fb = layer.getBuffer()
  for ix in [0..brushW]
    for iy in [0..brushH]
      i = (brushX + ix + (brushY + iy) * width)
      fb[i] += pressure * 0.2

  brushRect = [brushX, brushY, brushW+1, brushH+1]
  drawLayer(layer,[brushRect], gamma)
  getMainContext().drawImage(layer.canvas,
    brushRect[0], brushRect[1], brushRect[2], brushRect[3],
    offset.x + brushRect[0], offset.y + brushRect[1], brushRect[2], brushRect[3])

changeGamma = (value) ->
  gamma = value
  refresh()

refresh = () ->
  drawLayer(layer,[[0,0,width,height]], gamma)
  getMainContext().drawImage(layer.canvas, offset.x, offset.y)

# ---

$mainCanvas.mouseup (e) -> drawing = false
$mainCanvas.mousedown (e) ->
  drawing = true
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
  return Math.sin(x * y * 10)
  #return 0

refresh()

