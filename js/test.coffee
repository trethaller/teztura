
$mainCanvas = $('#canvas')
width = $mainCanvas.width()
height = $mainCanvas.height()


createCanvas = (width, height) ->
  c = document.createElement('canvas')
  c.width = width
  c.height = height
  return c

offscreenCtx = createCanvas(width,height).getContext '2d'


class FloatBuffer
  constructor: (@width, @height) ->
    @buffer = new ArrayBuffer @width * @height * 4
    @fbuffer = new Float32Array @buffer


offscreenImg = offscreenCtx.getImageData 0,0,width,height

drawing = false

fbuffer = new FloatBuffer(width,height)

`
function updateCanvas (fbuffer, ctx, imgData, rects) {
  var width = fbuffer.width;
  var height = fbuffer.height;
  var data = imgData.data;
  for(var i in rects) {
    var r = rects[i];
    var minX = r[0];
    var minY = r[1];
    var maxX = minX + r[2];
    var maxY = minY + r[3];
    for(var iy=minY; iy<maxY; ++iy) {
      var offset = iy * width;
      for(var ix=minX; ix<maxX; ++ix) {
        var fval = fbuffer[offset + ix];
        var val = (fval + 1.0) * 127
        var i = (offset + ix) << 2;
        data[i] = val;
        data[++i] = val;
        data[++i] = val;
        data[++i] = 0xff;
      }
    }

    ctx.putImageData(imgData, 0, 0, r[0], r[1], r[2], r[3])
  }
}

function fillBuffer(fbuffer, func) {
  var width = fbuffer.width;
  var height = fbuffer.height;
  var invw = 1.0 / width;
  var invh = 1.0 / height;
  for(var iy=0; iy<height; ++iy) {
    var off = iy * width;
    for(var ix=0; ix<width; ++ix) {
      fbuffer[off + ix] = func(ix * invw, iy * invh);
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
  brushX = e.pageX-$mainCanvas.position().left;
  brushY = e.pageY-$mainCanvas.position().top;
  brushW = 20
  brushH = 20

  pressure = getPenPressure()
  for ix in [0..brushW]
    for iy in [0..brushH]
      i = (brushX + ix + (brushY + iy) * width)
      fbuffer[i] += pressure * 0.2

  brushRect = [brushX, brushY, brushW, brushH]
  updateCanvas fbuffer,offscreenCtx,offscreenImg,[brushRect]
  getMainContext().drawImage(offscreenCtx.canvas,
    brushRect[0], brushRect[1], brushRect[2], brushRect[3],
    brushRect[0], brushRect[1], brushRect[2], brushRect[3])


$mainCanvas.mouseup (e) -> drawing = false
$mainCanvas.mousedown (e) ->
  drawing = true
  onDraw(e)
$mainCanvas.mousemove (e) ->
  if drawing
    onDraw(e)

# ---

fillBuffer fbuffer, (x,y) ->
  return Math.sin(x * y * 10)

updateCanvas fbuffer,offscreenCtx,offscreenImg,[[0,0,width,height]]

getMainContext().drawImage(offscreenCtx.canvas, 0, 0)


