




$mainCanvas = $('#canvas')
width = $mainCanvas.width()
height = $mainCanvas.height()

getWTPlugin = () ->
  return document.getElementById('wtPlugin')

createCanvas = (width, height) ->
  c = document.createElement('canvas')
  c.width = width
  c.height = height
  return c

offscreenCtx = createCanvas(width,height).getContext '2d'

#buffer = new ArrayBuffer width * height * 4
#fbuffer = new Float32Array buffer

#ibuffer8 = new Uint8ClampedArray buffer;
#ibuffer = new Uint32Array imgdata.data

offscreenCtx.fillRect 0,0,width,height

offscreenImg = offscreenCtx.getImageData 0,0,width,height

drawing = false


onDraw = (e) ->
  x = e.pageX-$mainCanvas.position().left;
  y = e.pageY-$mainCanvas.position().top;

  #[x, y] = [e.clientX, e.clientY]
  #ctx = e.target.getContext '2d'

  if not drawing
    return

  penAPI = getWTPlugin().penAPI
  pressure = 0.0
  if penAPI
    pressure = penAPI.pressure;

  lol = 5
  col = Math.round((1-pressure) * 255)
  data = offscreenImg.data
  for ix in [0..lol]
    for iy in [0..lol]
      i = (x + ix + (y + iy) * width)*4
      data[ i ]   = col
      data[ i+1 ] = col
      data[ i+2 ] = col
      data[ i+3 ] = 0xff
      #ibuffer[ x + ix + (y + iy) * width ] = 0xffff0080 + ix
  

  offscreenCtx.putImageData(offscreenImg, 0, 0, x, y, lol, lol)
  $mainCanvas[0].getContext('2d').drawImage(offscreenCtx.canvas, x, y, lol, lol, x, y, lol, lol)
  #$mainCanvas.getContext('2d').fillRect(x,y,lol,lol)

$mainCanvas.mouseup (e) -> drawing = false
$mainCanvas.mousedown (e) ->
  drawing = true
  onDraw(e)
$mainCanvas.mousemove (e) ->
  onDraw(e)


