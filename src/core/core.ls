
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

  str = "(function (rect, layer, #{opts.args}) {
    var invw = 2.0 / (rect.width - 1);
    var invh = 2.0 / (rect.height - 1);
    var offx = -(rect.x % 1.0) * invw - 1.0;
    var offy = -(rect.y % 1.0) * invh - 1.0;
    var fbw = layer.width;
    var fbh = layer.height;
    var dstData = layer.getBuffer();"
      
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
        var dsti = (Math.floor(rect.y) + sy) * layer.width + Math.floor(rect.x) + minx;
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
  min = Math.min
  max = Math.max
  cos = Math.cos
  sqrt = Math.sqrt
  pi = Math.PI
  return (x,y) -> 
    d = min(1.0, max(0.0, (sqrt(x*x + y*y) * hardnessPlus1 - hardness)))
    return cos(d * pi) * 0.5 + 0.5


export {
  genBlendFunc, genBrushFunc, getRoundBrushFunc
}