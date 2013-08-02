
class Vector
  constructor: (@x, @y) ->;
  distanceTo: (v) ->
    return Math.sqrt(squareDistanceTo(v))
  squareDistanceTo: (v) ->
    dx = @x - v.x
    dy = @y - v.y
    return dx*dx + dy*dy
  round: ()->
    return new Vector(Math.round(@x), Math.round(@y))
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
    nmaxy = Math.min(@y+@height, rect.y+rect.height)
    nx = Math.max(@x, rect.x)
    ny = Math.max(@y, rect.y)
    return new Rect(nx, ny, Math.max(0, nmaxx-nx), Math.max(0, nmaxy-ny))
  union: (rect) ->
    ret = new Rect(@x,@y,@width,@height)
    ret.extend(rect.topLeft())
    ret.extend(rect.bottomRight())
    return ret

  isEmpty: ()->
    return @width<=0 or @height<=0

  round: ()->
    return new Rect(
      Math.floor(@x),
      Math.floor(@y),
      Math.ceil(@width),
      Math.ceil(@height))

  extend: (obj) ->
    if obj.width?
      @extend(obj.topLeft())
      @extend(obj.bottomRight())
    else
      if obj.x < @x
        @width += @x - obj.x
        @x = obj.x
      else
        @width = Math.max(@width, obj.x - @x)
      if obj.y < @y
        @height += @y - obj.y
        @y = obj.y
      else
        @height = Math.max(@height, obj.y - @y)
    
  topLeft: ()->
    return new Vector(@x,@y)
  bottomRight: ()->
    return new Vector(@x+@width, @y+@height)

Rect.Empty = new Rect(0,0,0,0)

class FloatBuffer
  constructor: (@width, @height) ->
    @buffer = new ArrayBuffer @width * @height * 4
    @fbuffer = new Float32Array @buffer


class Layer
  constructor: (@width, @height) ->
    @data = new FloatBuffer(@width, @height)

  getRect: () ->
    return new Rect(0,0,@width,@height)

  getBuffer: () ->
    return @data.fbuffer

  getAt: (pos)->
    ipos = pos.round()
    return @data.fbuffer[ ipos.y * @width + ipos.x ]


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

GammaRenderer = (()->
  properties = 
    gamma: 1.0

  `function renderLayer (layer, view, rects) {
    var width = layer.width;
    var height = layer.height;
    var imgData = view.imageData.data;
    var fb = layer.getBuffer();
    var gamma = properties.gamma;
    for(var i in rects) {
      var r = rects[i];
      var minX = r.x;
      var minY = r.y;
      var maxX = minX + r.width;
      var maxY = minY + r.height;
      for(var iy=minY; iy<=maxY; ++iy) {
        var offset = iy * width;
        for(var ix=minX; ix<=maxX; ++ix) {
          var fval = fb[offset + ix];
          var val = Math.pow((fval + 1.0) * 0.5, gamma) * 255.0;
          var i = (offset + ix) << 2;
          imgData[i] = val;
          imgData[++i] = val;
          imgData[++i] = val;
          imgData[++i] = 0xff;
        }
      }
      view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);
    }
  }`

  return {properties, renderLayer}
)();

`
function fillLayer(layer, func) {
  var width = layer.width;
  var height = layer.height;
  var invw = 2.0 / (width - 1);
  var invh = 2.0 / (height - 1);
  var fb = layer.getBuffer();
  for(var iy=0; iy<height; ++iy) {
    var off = iy * width;
    for(var ix=0; ix<width; ++ix) {
      fb[off] = func(ix * invw - 1.0, iy * invh - 1.0);
      ++off;
    }
  }
}
`

genBlendFunc = (args, expression)->
  expr = expression
    .replace(/{dst}/g, "dstData[dsti]")
    .replace(/{src}/g, "srcData[srci]")

  str = "
    (function (pos, srcFb, dstFb, #{args}) {
      var minx = Math.max(0, -pos.x);
      var miny = Math.max(0, -pos.y);
      var sw = Math.min(srcFb.width, dstFb.width - pos.x);
      var sh = Math.min(srcFb.height, dstFb.height - pos.y);
      var srcData = srcFb.getBuffer();
      var dstData = dstFb.getBuffer();
      for(var sy=miny; sy<sh; ++sy) {
        var srci = sy * srcFb.width + minx;
        var dsti = (pos.y + sy) * dstFb.width + pos.x + minx;
        for(var sx=minx; sx<sw; ++sx) {
          #{expr};
          ++dsti;
          ++srci;
        }
      }
    })"
  #console.log("Generating blend function", str)
  return eval(str)

genBrushFunc = (args, brushExp, blendExp)->
  blendExp = blendExp
    .replace(/{dst}/g, "dstData[dsti]")
    .replace(/{src}/g, "_tmp")

  brushExp = brushExp
    .replace(/{out}/g, "_tmp")

  str = "
    (function (rect, dstFb, #{args}) {
      var minx = Math.max(0, -rect.x);
      var miny = Math.max(0, -rect.y);
      var sw = Math.min(rect.width, dstFb.width - rect.x);
      var sh = Math.min(rect.height, dstFb.height - rect.y);
      var invw = 2.0 / (rect.width - 1);
      var invh = 2.0 / (rect.height - 1);
      var dstData = dstFb.getBuffer();
      for(var sy=miny; sy<sh; ++sy) {
        var dsti = (rect.y + sy) * dstFb.width + rect.x + minx;
        var y = sy * invh - 1.0;
        for(var sx=minx; sx<sw; ++sx) {
          var x = sx * invw - 1.0;
          var _tmp = 0.0;
          #{brushExp};
          #{blendExp};
          ++dsti;
        }
      }
    })"
  #console.log("Generating brush function", str)
  return eval(str)


getRoundBrushFunc = (hardness) ->
  hardnessPlus1 = hardness + 1.0
  return (x,y) -> 
    d = Math.min(1.0, Math.max(0.0, (Math.sqrt(x*x + y*y) * hardnessPlus1 - hardness)))
    return Math.cos(d * Math.PI) * 0.5 + 0.5

if module?
  module.exports = {Vector, Rect, FloatBuffer, Layer}