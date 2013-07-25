
class Point
  constructor: (@x, @y) ->;

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
    @fbuffer = new FloatBuffer(@width, @height)
    @canvas = @createCanvas(@width,@height)
    @context = @canvas.getContext '2d'
    @imageData = @context.getImageData(0,0,width,height)

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
      return new Point f2(pts[0].x, pts[1].x, t), f2(pts[0].y, pts[1].y, t)
    else
      return new Point f3(pts[0].x, pts[1].x, pts[2].x, t), f3(pts[0].y, pts[1].y, pts[2].y, t)

if module?
  module.exports = {Point, Rect, FloatBuffer, Layer}