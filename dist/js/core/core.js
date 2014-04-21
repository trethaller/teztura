/*
Bezier =
  quadratic: (pts, t)->
    lerp = (a, b, t) ->
      a * t + b * (1-t)
    f3 = (v1, v2, v3, t) ->
      lerp(lerp(v1, v2, t), lerp(v2, v3, t), t)
    f2 = (v1, v2, t) ->
      lerp(v1, v2, t)

    if pts.length is 1
      return pts[0]
    else if pts.length is 2
      return new Vec2 f2(pts[0].x, pts[1].x, t), f2(pts[0].y, pts[1].y, t)
    else
      return new Vec2 f3(pts[0].x, pts[1].x, pts[2].x, t), f3(pts[0].y, pts[1].y, pts[2].y, t)
*/
(function(){
  var genBlendFunc, genBrushFunc, getRoundBrushFunc, ref$, out$ = typeof exports != 'undefined' && exports || this;
  
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
  
  genBlendFunc = function(args, expression){
    var expr, str;
    expr = expression.replace(/{dst}/g, "dstData[dsti]").replace(/{src}/g, "srcData[srci]");
    str = "(function (pos, srcFb, dstFb, " + args + ") {var minx = Math.max(0, -pos.x);var miny = Math.max(0, -pos.y);var sw = Math.min(srcFb.width, dstFb.width - pos.x);var sh = Math.min(srcFb.height, dstFb.height - pos.y);var srcData = srcFb.getBuffer();var dstData = dstFb.getBuffer();for(var sy=miny; sy<sh; ++sy) {var srci = sy * srcFb.width + minx;var dsti = (pos.y + sy) * dstFb.width + pos.x + minx;for(var sx=minx; sx<sw; ++sx) {" + expr + ";++dsti;++srci;}}})";
    return eval(str);
  };
  genBrushFunc = function(opts){
    var blendExp, brushExp, str;
    blendExp = opts.blendExp.replace(/{dst}/g, "dstData[dsti]").replace(/{src}/g, "_tmp");
    brushExp = opts.brushExp.replace(/{out}/g, "_tmp");
    str = "(function (rect, layer, " + opts.args + ") {var invw = 2.0 / (rect.width - 1);var invh = 2.0 / (rect.height - 1);var offx = -(rect.x % 1.0) * invw - 1.0;var offy = -(rect.y % 1.0) * invh - 1.0;var fbw = layer.width;var fbh = layer.height;var dstData = layer.getBuffer();";
    str += opts.tiling
      ? "var minx = Math.floor(rect.x) + fbw;var miny = Math.floor(rect.y) + fbh;var sw = Math.round(rect.width);var sh = Math.round(rect.height);for(var sy=0; sy<sh; ++sy) {var y = sy * invh + offy;for(var sx=0; sx<sw; ++sx) {var x = sx * invw + offx;var dsti = ((sy + miny) % fbh) * fbw + ((sx + minx) % fbw);var _tmp = 0.0;" + brushExp + ";" + blendExp + ";}}"
      : "var minx = Math.floor(Math.max(0, -rect.x));var miny = Math.floor(Math.max(0, -rect.y));var sw = Math.round(Math.min(rect.width, fbw - rect.x));var sh = Math.round(Math.min(rect.height, fbh - rect.y));for(var sy=miny; sy<sh; ++sy) {var dsti = (Math.floor(rect.y) + sy) * layer.width + Math.floor(rect.x) + minx;var y = sy * invh + offy;for(var sx=minx; sx<sw; ++sx) {var x = sx * invw + offx;var _tmp = 0.0;" + brushExp + ";" + blendExp + ";++dsti;}}";
    str += "});";
    return eval(str);
  };
  getRoundBrushFunc = function(hardness){
    var hardnessPlus1;
    hardnessPlus1 = hardness + 1.0;
    return function(x, y){
      var d;
      d = Math.min(1.0, Math.max(0.0, Math.sqrt(x * x + y * y) * hardnessPlus1 - hardness));
      return Math.cos(d * Math.PI) * 0.5 + 0.5;
    };
  };
  ref$ = out$;
  ref$.fillLayer = fillLayer;
  ref$.genBlendFunc = genBlendFunc;
  ref$.genBrushFunc = genBrushFunc;
  ref$.getRoundBrushFunc = getRoundBrushFunc;
}).call(this);
