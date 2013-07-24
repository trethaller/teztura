




$can = $('#canvas')[0]
width = $can.width
height = $can.height

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

$('#canvas').mousemove (e) ->
  [x, y] = [e.clientX, e.clientY]
  #ctx = e.target.getContext '2d'

  lol = 10  
  data = offscreenImg.data
  for ix in [0..lol]
    for iy in [0..lol]
      i = (x + ix + (y + iy) * width)*4
      data[ i ] = 0x10
      data[ i+1 ] = ix*10
      data[ i+2 ] = iy*10
      data[ i+3 ] = 0xff
      #ibuffer[ x + ix + (y + iy) * width ] = 0xffff0080 + ix
  

  offscreenCtx.putImageData(offscreenImg, 0, 0, x, y, lol, lol)
  $can.getContext('2d').drawImage(offscreenCtx.canvas, x, y, lol, lol, x, y, lol, lol)
  #$can.getContext('2d').fillRect(x,y,lol,lol)

