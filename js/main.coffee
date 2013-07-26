
$mainCanvas = $('#canvas')
width = $mainCanvas.width()
height = $mainCanvas.height()

class Brush
  stroke: (layer, start, end, pressure) -> ;
  move: (pos, intensity) -> ;
  beginStroke: (pos) -> ;
  endStroke: (pos) -> ;

class TestBrush1
  drawing: false
  lastpos: null
  accumulator: 0.0
  stepSize: 4.0

  move: (pos, intensity) ->;
  draw: (layer, pos, intensity) ->
    delt = pos.sub(lastpos)
    length = delt.length()
    dir = delt.scale(1.0 / length)
    while(@accumulator + stepSize <= length)
      @accumulator += @stepSize
      pt = pos + dir.scale(@accumulator)

    @accumulator -= length
    lastpos = pos

  beginStroke: (pos) ->
    drawing = true
    @accumulator = 0
  endStroke: (pos) ->
    lastpos = null
    drawing = false


drawing = false
gamma = 1.0
layer = new Layer(width, height)
offset = new Vector(50, 30)

`
function drawLayer (layer, rects, gamma) {
  var width = layer.width;
  var height = layer.height;
  var imgData = layer.imageData.data;
  var fb = layer.data.fbuffer;
  for(var i in rects) {
    var r = rects[i];
    var minX = r[0];
    var minY = r[1];
    var maxX = minX + r[2];
    var maxY = minY + r[3];
    for(var iy=minY; iy<maxY; ++iy) {
      var offset = iy * width;
      for(var ix=minX; ix<maxX; ++ix) {
        var fval = fb[offset + ix];
        var val = Math.pow((fval + 1.0) * 0.5, gamma) * 255.0;
        var i = (offset + ix) << 2;
        imgData[i] = val;
        imgData[++i] = val;
        imgData[++i] = val;
        imgData[++i] = 0xff;
      }
    }

    layer.context.putImageData(layer.imageData, 0, 0, r[0], r[1], r[2], r[3])
  }
}

function fillLayer(layer, func) {
  var width = layer.width;
  var height = layer.height;
  var invw = 1.0 / width;
  var invh = 1.0 / height;
  var fb = layer.data.fbuffer;
  for(var iy=0; iy<height; ++iy) {
    var off = iy * width;
    for(var ix=0; ix<width; ++ix) {
      fb[off + ix] = func(ix * invw, iy * invh);
    }
  }
}
`

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
  fb = layer.data.fbuffer
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

