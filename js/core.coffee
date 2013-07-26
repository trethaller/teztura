
class Vector
  constructor: (@x, @y) ->;
  distanceTo: (v) ->
    return Math.sqrt(squareDistanceTo(v))
  squareDistanceTo: (v) ->
    dx = @x - v.x
    dy = @y - v.y
    return dx*dx + dy*dy
  add: (v) ->
    return new Vector(@x+v.x, @y+v.y)
  sub: (v) ->
    return new Vector(@x-v.x, @y-v.y)
  scale: (s) ->
    return new Vector(@x*s, @y*s)
  length: () ->
    return Math.sqrt(@squareLength())
  squareLength: () ->
    return @x*@x+@y*@y
  normalized: () ->
    return @scale(1.0 / @length())

class Rect
  constructor: (@x, @y, @width, @height) -> ;
  intersect: (rect) ->
    nmaxx = Math.min(@x+@width, rect.x+rect.width)
    nmaxy = Math.min(@x+@width, rect.x+rect.width)
    nx = Math.max(@x, rect.x)
    ny = Math.max(@y, rect.y)
    return new Rect(nx, ny, Math.max(0, nmaxx-nx), Math.max(0, nmaxy-ny))

class FloatBuffer
  constructor: (@width, @height) ->
    @buffer = new ArrayBuffer @width * @height * 4
    @fbuffer = new Float32Array @buffer

class Layer
  constructor: (@width, @height) ->
    @data = new FloatBuffer(@width, @height)
    @canvas = @createCanvas(@width,@height)
    @context = @canvas.getContext '2d'
    @imageData = @context.getImageData(0,0,width,height)


  getBuffer: () ->
    return @data.fbuffer

  createCanvas: (width, height) ->
    c = document.createElement('canvas')
    c.width = width
    c.height = height
    return c


Bezier =
  quadratic: (pts, t)->
    lerp = (a, b, t) ->
      return (a * t + b * (1-t))
    f3 = (v1, v2, v3, t) ->
      return lerp(lerp(v1, v2, t), lerp(v2, v3, t), t)
    f2 = (v1, v2, t) ->
      return lerp(v1, v2, t)

    if pts.length is 1
      return pts[0]
    else if pts.length is 2
      return new Vector f2(pts[0].x, pts[1].x, t), f2(pts[0].y, pts[1].y, t)
    else
      return new Vector f3(pts[0].x, pts[1].x, pts[2].x, t), f3(pts[0].y, pts[1].y, pts[2].y, t)


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
    fb = layer.getBuffer()
    if @lastpos?
      delt = pos.sub(@lastpos)
      length = delt.length()
      dir = delt.scale(1.0 / length)
      while(@accumulator + @stepSize <= length)
        @accumulator += @stepSize
        pt = @lastpos.add(dir.scale(@accumulator))
        fb[ Math.floor(pt.x) + Math.floor(pt.y) * layer.width ] = 1.0
      @accumulator -= length
    else
      fb[ Math.floor(pos.x) + Math.floor(pos.y) * layer.width ] = 1.0

    @lastpos = pos

  beginStroke: () ->
    @drawing = true
    @accumulator = 0
  endStroke: () ->
    @lastpos = null
    @drawing = false


`
function drawLayer (layer, rects, gamma) {
  var width = layer.width;
  var height = layer.height;
  var imgData = layer.imageData.data;
  var fb = layer.getBuffer();
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
  var fb = layer.getBuffer();
  for(var iy=0; iy<height; ++iy) {
    var off = iy * width;
    for(var ix=0; ix<width; ++ix) {
      fb[off + ix] = func(ix * invw, iy * invh);
    }
  }
}
`


if module?
  module.exports = {Vector, Rect, FloatBuffer, Layer}