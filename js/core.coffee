
class Vec2
  constructor: (@x, @y) ->;
  clone: ()->
    return new Vec2(@x,@y)
  distanceTo: (v) ->
    return Math.sqrt(squareDistanceTo(v))
  squareDistanceTo: (v) ->
    dx = @x - v.x
    dy = @y - v.y
    return dx*dx + dy*dy
  round: ()->
    return new Vec2(Math.round(@x), Math.round(@y))
  add: (v) ->
    return new Vec2(@x+v.x, @y+v.y)
  sub: (v) ->
    return new Vec2(@x-v.x, @y-v.y)
  scale: (s) ->
    return new Vec2(@x*s, @y*s)
  length: () ->
    return Math.sqrt(@squareLength())
  squareLength: () ->
    return @x*@x+@y*@y
  normalized: () ->
    return @scale(1.0 / @length())
  wrap: (w,h)->
    return new Vec2(
      (@x % w + w) % w,
      (@y % h + h) % h)

class Vec3
  constructor: (@x, @y, @z) ->;
  add: (v) ->
    return new Vec3(@x+v.x, @y+v.y, @z+v.z)
  sub: (v) ->
    return new Vec3(@x-v.x, @y-v.y, @z-v.z)
  scale: (s) ->
    return new Vec3(@x*s, @y*s, @z*s)
  length: () ->
    return Math.sqrt(@squareLength())
  squareLength: () ->
    return @x*@x+@y*@y+@z*@z
  normalized: () ->
    return @scale(1.0 / @length())
  cross: (v)->
    return new Vec3(
      (@y * v.z - @z * v.y),
      (@z * v.x - @x * v.z),
      (@x * v.y - @y * v.x))
  dot: (v)->
    return @x+v.x + @y+v.y + @z+v.z

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

  clone: ->
    return new Rect(@x, @y, @width, @height)

  offset: (vec)->
    return new Rect(@x+vec.x, @y+vec.y, @width, @height)

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
    return new Vec2(@x,@y)
  bottomRight: ()->
    return new Vec2(@x+@width, @y+@height)

Rect.Empty = new Rect(0,0,0,0)

class FloatBuffer
  constructor: (@width, @height) ->
    @buffer = new ArrayBuffer @width * @height * 4
    @fbuffer = new Float32Array @buffer


class Layer
  constructor: (@width, @height) ->
    @data = new FloatBuffer(@width, @height)

  getRect: ->
    return new Rect(0,0,@width,@height)

  getBuffer: ->
    return @data.fbuffer

  getAt: (pos)->
    ipos = pos.wrap(@width, @height).round()
    return @data.fbuffer[ ipos.y * @width + ipos.x ]

  getNormalAt: (pos)->
    p = pos.round()
    fb = @data.fbuffer

  getCopy: (rect)->
    srcData = @data.buffer
    dstData = new ArrayBuffer(rect.width * rect.height * 4)
    `
    for(var iy=0; iy<rect.height; ++iy) {
      var src = new Uint32Array(srcData, 4 * ((iy + rect.y) * this.width + rect.x), rect.width);
      var dst = new Uint32Array(dstData, 4 * iy * rect.width, rect.width);
      dst.set(src);
    }`
    return dstData

  setData: (buffer, rect)->
    dstData = @data.buffer
    `
    for(var iy=0; iy<rect.height; ++iy) {
      var src = new Uint32Array(buffer, 4 * iy * rect.width, rect.width);
      var dstOff = 4 * ((iy + rect.y) * this.width + rect.x);
      var dst = new Uint32Array(dstData, dstOff, rect.width);
      dst.set(src);
    }`
    return

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
      return new Vec2 f2(pts[0].x, pts[1].x, t), f2(pts[0].y, pts[1].y, t)
    else
      return new Vec2 f3(pts[0].x, pts[1].x, pts[2].x, t), f3(pts[0].y, pts[1].y, pts[2].y, t)

GammaRenderer = (()->
  description = 
    name: "Height map"

  properties = 
    gamma: 1.0

  `function renderLayer (layer, view, rects) {
    var width = layer.width;
    var height = layer.height;
    var destBuffer = new Uint32Array(view.imageData.data.buffer)
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
          fval = fval > 1.0 ? 1.0 : (fval < -1.0 ? -1.0 : fval)
          var val = Math.round(Math.pow((fval + 1.0) * 0.5, gamma) * 255.0);
          destBuffer[offset + ix] =
            (val) | (val << 8) | (val << 16) | 0xff000000;
        }
      }
      view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);
    }
  }`

  return {description, properties, renderLayer}
)();

GradientRenderer = (()->
  description = 
    name: "Gradient"

  properties = 
    gradient: null

  `function renderLayer (layer, view, rects) {
    if(properties.gradient == null)
      return;
    var width = layer.width;
    var height = layer.height;
    var imgData = view.imageData.data;
    var destBuffer = new Uint32Array(view.imageData.data.buffer)
    var fb = layer.getBuffer();
    var gamma = properties.gamma;
    var lut = properties.gradient.lut
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
          var lookup = lut[
            Math.round(
              Math.min(511,
                Math.max(0,
                  256.0 * (1.0 + fval)
                )
              )
            )
          ];
          var i = (offset + ix);
          destBuffer[i] = lookup;
        }
      }
      view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);
    }
  }`

  return {description, properties, renderLayer}
)();

NormalRenderer = (()->
  description =
    name: "Normal map"

  properties = 
    gain: 4.0

  sample = (res, x, y)->
    return "var #{res} = fb[ ((#{y} + height) % height) * width + ((#{x} + width) % width) ];\n"

  str = "(function renderLayer (layer, view, rects) {
    var width = layer.width;
    var height = layer.height;
    var imgData = view.imageData.data;
    var fb = layer.getBuffer();
    var dz = 1.0 / (properties.gain);
    for(var i in rects) {
      var r = rects[i];
      var minX = r.x;
      var minY = r.y;
      var maxX = minX + r.width;
      var maxY = minY + r.height;
      for(var iy=minY; iy<=maxY; ++iy) {
        for(var ix=minX; ix<=maxX; ++ix) {
          " +
          sample('sx1', 'ix-1', 'iy') +
          sample('sx2', 'ix+1', 'iy') +
          sample('sy1', 'ix',   'iy-1') +
          sample('sy2', 'ix',   'iy+1') + "
          var dx = sx2 - sx1;
          var dy = sy2 - sy1;
          var fac = 128.0 / Math.sqrt(dx*dx + dy*dy + dz*dz);
          var i = (iy * width + ix) << 2;
          imgData[i]   = dx * fac + 127.0;
          imgData[++i] = dy * fac + 127.0;
          imgData[++i] = dz * fac + 127.0;
          imgData[++i] = 0xff;
        }
      }
      view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);
    }
  })"
  
  renderLayer = eval(str);

  return {description, properties, renderLayer}
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
  return eval(str)

genBrushFunc = (opts)->
  blendExp = opts.blendExp
    .replace(/{dst}/g, "dstData[dsti]")
    .replace(/{src}/g, "_tmp")

  brushExp = opts.brushExp
    .replace(/{out}/g, "_tmp")

  str = "(function (rect, dstFb, #{opts.args}) {
    var invw = 2.0 / (rect.width - 1);
    var invh = 2.0 / (rect.height - 1);
    var offx = -(rect.x % 1.0) * invw - 1.0;
    var offy = -(rect.y % 1.0) * invh - 1.0;
    var fbw = dstFb.width;
    var fbh = dstFb.height;
    var dstData = dstFb.getBuffer();"
      
  str += if opts.tiling then "
      var minx = Math.floor(rect.x) + fbw;
      var miny = Math.floor(rect.y) + fbh;
      var sw = Math.round(rect.width);
      var sh = Math.round(rect.height);
      
      for(var sy=0; sy<sh; ++sy) {
        var y = sy * invh + offy;
        for(var sx=0; sx<sw; ++sx) {
          var x = sx * invw + offx;
          var dsti = ((sy + miny) % fbh) * fbw + ((sx + minx) % fbw);
          var _tmp = 0.0;
          #{brushExp};
          #{blendExp};
        }
      }"
  else "
      var minx = Math.floor(Math.max(0, -rect.x));
      var miny = Math.floor(Math.max(0, -rect.y));
      var sw = Math.round(Math.min(rect.width, fbw - rect.x));
      var sh = Math.round(Math.min(rect.height, fbh - rect.y));
      for(var sy=miny; sy<sh; ++sy) {
        var dsti = (Math.floor(rect.y) + sy) * dstFb.width + Math.floor(rect.x) + minx;
        var y = sy * invh + offy;
        for(var sx=minx; sx<sw; ++sx) {
          var x = sx * invw + offx;
          var _tmp = 0.0;
          #{brushExp};
          #{blendExp};
          ++dsti;
        }
      }"
  str += "});"

  return eval(str)

getRoundBrushFunc = (hardness) ->
  hardnessPlus1 = hardness + 1.0
  return (x,y) -> 
    d = Math.min(1.0, Math.max(0.0, (Math.sqrt(x*x + y*y) * hardnessPlus1 - hardness)))
    return Math.cos(d * Math.PI) * 0.5 + 0.5

if module?
  module.exports = {Vec2, Vec3, Rect, FloatBuffer, Layer}