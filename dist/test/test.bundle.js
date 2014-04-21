(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
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

},{}],2:[function(require,module,exports){
(function(){
  var Layer, out$ = typeof exports != 'undefined' && exports || this;
  Layer = (function(){
    Layer.displayName = 'Layer';
    var prototype = Layer.prototype, constructor = Layer;
    function Layer(width, height){
      this.width = width;
      this.height = height;
      this.buffer = new ArrayBuffer(this.width * this.height * 4);
      this.fbuffer = new Float32Array(this.buffer);
    }
    prototype.getRect = function(){
      return new Rect(0, 0, this.width, this.height);
    };
    prototype.getBuffer = function(){
      return this.fbuffer;
    };
    prototype.getAt = function(pos){
      var ipos;
      ipos = pos.wrap(this.width, this.height).round();
      return this.fbuffer[ipos.y * this.width + ipos.x];
    };
    prototype.getNormalAt = function(pos, rad){
      var p, fb, px, py, sx1, sx2, sy1, sy2, xvec, yvec, norm;
      p = pos.round();
      fb = this.fbuffer;
      px = Math.round(pos.x);
      py = Math.round(pos.y);
      sx1 = fb[py * this.width + pxRad % this.width];
      sx2 = fb[py * this.width + (px + rad) % this.width];
      sy1 = fb[(pyRad % this.height) * this.width + px];
      sy2 = fb[((py + rad) % this.height) * this.width + px];
      xvec = new Vec3(rad * 2, 0, sx2 - sx1);
      yvec = new Vec3(0, rad * 2, sy2 - sy1);
      return norm = xvec.cross(yvec).normalized();
    };
    prototype.getCopy = function(rect){
      var srcData, dstData;
      srcData = this.buffer;
      dstData = new ArrayBuffer(rect.width * rect.height * 4);
      
      for(var iy=0; iy<rect.height; ++iy) {
        var src = new Uint32Array(srcData, 4 * ((iy + rect.y) * this.width + rect.x), rect.width);
        var dst = new Uint32Array(dstData, 4 * iy * rect.width, rect.width);
        dst.set(src);
      }
      return dstData;
    };
    prototype.setData = function(buffer, rect){
      var dstData;
      dstData = this.buffer;
      
      for(var iy=0; iy<rect.height; ++iy) {
        var src = new Uint32Array(buffer, 4 * iy * rect.width, rect.width);
        var dstOff = 4 * ((iy + rect.y) * this.width + rect.x);
        var dst = new Uint32Array(dstData, dstOff, rect.width);
        dst.set(src);
      }
    };
    prototype.fill = function(fn){
      var invw, invh, fb, width, height, i$, iy, lresult$, i, j$, ix, results$ = [];
      invw = 2.0 / (this.width - 1);
      invh = 2.0 / (this.height - 1);
      fb = this.getBuffer();
      width = this.width;
      height = this.height;
      for (i$ = 0; i$ < height; ++i$) {
        iy = i$;
        lresult$ = [];
        i = iy * width;
        for (j$ = 0; j$ < width; ++j$) {
          ix = j$;
          fb[i] = fn(ix * invw - 1.0, iy * invh - 1.0);
          lresult$.push(++i);
        }
        results$.push(lresult$);
      }
      return results$;
    };
    return Layer;
  }());
  out$.Layer = Layer;
}).call(this);

},{}],3:[function(require,module,exports){
GammaRenderer = (function() {

  var properties = {
    gamma: 1.0
  };

  function renderLayer (layer, view, rects) {
    var width = layer.width;
    var height = layer.height;
    var imgData = view.imageData.data;
    var fb = layer.getBuffer();
    var gamma = properties.gamma;
    for(var ri in rects) {
      var r = rects[ri];
      var minX = r.x;
      var minY = r.y;
      var maxX = minX + r.width;
      var maxY = minY + r.height;
      for(var iy=minY; iy<=maxY; ++iy) {
        var offset = iy * width;
        for(var ix=minX; ix<=maxX; ++ix) {
          var fval = fb[offset + ix];
          fval = fval > 1.0 ? 1.0 : (fval < -1.0 ? -1.0 : fval);
          var val = Math.round(Math.pow((fval + 1.0) * 0.5, gamma) * 255.0);
          var off = (offset + ix) << 2;
          imgData[off] = val;
          imgData[off+1] = val;
          imgData[off+2] = val;
          imgData[off+3] = 0xff;
        }
      }
      view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);
    }
  }

  return {
    description: {
      name: "Height map"
    },
    properties: properties,
    renderLayer: renderLayer
  };
})();

export { GammaRenderer }
},{}],4:[function(require,module,exports){
(function(){
  var Core, Layer, GammaRenderer, $root, testSection;
  Core = require('../core/core');
  Layer = require('../core/layer');
  GammaRenderer = require('../renderers/gamma-renderer');
  $root = $('#tests-root');
  testSection = function(desc, fn){
    var $el;
    $('<h2>').text(desc).appendTo($root);
    $el = $('<div>').appendTo($root);
    $('<hr>').appendTo($root);
    return fn($el);
  };
  testSection('Blend modes', function($el){
    var width, height, $can, ctx, layer, brush, view;
    width = 400;
    height = 100;
    $can = $('#canvas').width(width).height(height).appendTo($el);
    ctx = $can[0].getContext('2d');
    layer = new Layer(width, height);
    brush = new Layer(height, height);
    brush.fill(Core.getRoundBrushFunc(0));
    layer.fill(function(x, y){
      x += 1;
      y += 1;
      return (Math.round(x * 40) % 2) * 0.1 - (Math.round(y * 40) % 2) * 0.1;
    });
    view = {
      canvas: $can[0],
      context: ctx,
      imageData: ctx.getImageData(0, 0, width, height)
    };
    GammaRenderer.renderLayer(layer, view, [new Rect(0, 0, width, height)]);
    return ctx.drawImage(canvas, 0, 0);
  });
}).call(this);

},{"../core/core":1,"../core/layer":2,"../renderers/gamma-renderer":3}]},{},[4])