
$mainCanvas = $('#canvas')
width = $mainCanvas.width()
height = $mainCanvas.height()


createCanvas = (width, height) ->
  c = document.createElement('canvas')
  c.width = width
  c.height = height
  return c


class Point
  constructor: (@x, @y) ->;

class FloatBuffer
  constructor: (@width, @height) ->
    @buffer = new ArrayBuffer @width * @height * 4
    @fbuffer = new Float32Array @buffer

class Layer
  constructor: (@width, @height) ->
    @fbuffer = new FloatBuffer(@width, @height)
    @canvas = createCanvas(@width,@height)
    @context = @canvas.getContext '2d'
    @imageData = @context.getImageData(0,0,width,height)

drawing = false
gamma = 1.0
layer = new Layer(width, height)
offset = new Point(50, 30)

`
function updateLayer (layer, rects, gamma) {
  var width = layer.width;
  var height = layer.height;
  var data = layer.imageData.data;
  var fb = layer.fbuffer;
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
        data[i] = val;
        data[++i] = val;
        data[++i] = val;
        data[++i] = 0xff;
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
  var fb = layer.fbuffer;
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
  fb = layer.fbuffer
  for ix in [0..brushW]
    for iy in [0..brushH]
      i = (brushX + ix + (brushY + iy) * width)
      fb[i] += pressure * 0.2

  brushRect = [brushX, brushY, brushW+1, brushH+1]
  updateLayer(layer,[brushRect], gamma)
  getMainContext().drawImage(layer.canvas,
    brushRect[0], brushRect[1], brushRect[2], brushRect[3],
    offset.x + brushRect[0], offset.y + brushRect[1], brushRect[2], brushRect[3])

changeGamma = (value) ->
  gamma = value
  refresh()

refresh = () ->
  updateLayer(layer,[[0,0,width,height]], gamma)
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

