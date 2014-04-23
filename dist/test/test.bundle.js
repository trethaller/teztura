(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function(){
  var genBlendFunc, genBrushFunc, getRoundBrushFunc, ref$, out$ = typeof exports != 'undefined' && exports || this;
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
    var hardnessPlus1, min, max, cos, sqrt, pi;
    hardnessPlus1 = hardness + 1.0;
    min = Math.min;
    max = Math.max;
    cos = Math.cos;
    sqrt = Math.sqrt;
    pi = Math.PI;
    return function(x, y){
      var d;
      d = min(1.0, max(0.0, sqrt(x * x + y * y) * hardnessPlus1 - hardness));
      return cos(d * pi) * 0.5 + 0.5;
    };
  };
  ref$ = out$;
  ref$.genBlendFunc = genBlendFunc;
  ref$.genBrushFunc = genBrushFunc;
  ref$.getRoundBrushFunc = getRoundBrushFunc;
}).call(this);

},{}],2:[function(require,module,exports){
(function(){
  var Rect, Layer;
  Rect = require('../core/rect');
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
  module.exports = Layer;
}).call(this);

},{"../core/rect":3}],3:[function(require,module,exports){
(function(){
  var Vec2, Rect;
  Vec2 = require('./vec').Vec2;
  Rect = (function(){
    Rect.displayName = 'Rect';
    var prototype = Rect.prototype, constructor = Rect;
    function Rect(x, y, width, height){
      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
    }
    prototype.intersect = function(rect){
      var nmaxx, nmaxy, nx, ny;
      nmaxx = Math.min(this.x + this.width, rect.x + rect.width);
      nmaxy = Math.min(this.y + this.height, rect.y + rect.height);
      nx = Math.max(this.x, rect.x);
      ny = Math.max(this.y, rect.y);
      return new Rect(nx, ny, Math.max(0, nmaxx - nx), Math.max(0, nmaxy - ny));
    };
    prototype.union = function(rect){
      var x$;
      x$ = new Rect(this.x, this.y, this.width, this.height);
      x$.extend(rect.topLeft());
      x$.extend(rect.bottomRight());
      return x$;
    };
    prototype.clone = function(){
      return new Rect(this.x, this.y, this.width, this.height);
    };
    prototype.offset = function(vec){
      return new Rect(this.x + vec.x, this.y + vec.y, this.width, this.height);
    };
    prototype.isEmpty = function(){
      return this.width <= 0 || this.height <= 0;
    };
    prototype.round = function(){
      return new Rect(Math.floor(this.x), Math.floor(this.y), Math.ceil(this.width), Math.ceil(this.height));
    };
    prototype.extend = function(obj){
      if (obj.width != null) {
        this.extend(obj.topLeft());
        return this.extend(obj.bottomRight());
      } else {
        if (obj.x < this.x) {
          this.width += this.x - obj.x;
          this.x = obj.x;
        } else {
          this.width = Math.max(this.width, obj.x - this.x);
        }
        if (obj.y < this.y) {
          this.height += this.y - obj.y;
          return this.y = obj.y;
        } else {
          return this.height = Math.max(this.height, obj.y - this.y);
        }
      }
    };
    prototype.topLeft = function(){
      return new Vec2(this.x, this.y);
    };
    prototype.bottomRight = function(){
      return new Vec2(this.x + this.width, this.y + this.height);
    };
    return Rect;
  }());
  Rect.Empty = new Rect(0, 0, 0, 0);
  module.exports = Rect;
}).call(this);

},{"./vec":4}],4:[function(require,module,exports){
(function(){
  var Vec2, Vec3, ref$, out$ = typeof exports != 'undefined' && exports || this;
  Vec2 = (function(){
    Vec2.displayName = 'Vec2';
    var prototype = Vec2.prototype, constructor = Vec2;
    function Vec2(x, y){
      this.x = x;
      this.y = y;
    }
    prototype.clone = function(){
      return new Vec2(this.x, this.y);
    };
    prototype.distanceTo = function(v){
      return Math.sqrt(squareDistanceTo(v));
    };
    prototype.squareDistanceTo = function(v){
      var dx, dy;
      dx = this.x - v.x;
      dy = this.y - v.y;
      return dx * dx + dy * dy;
    };
    prototype.round = function(){
      return new Vec2(Math.round(this.x), Math.round(this.y));
    };
    prototype.add = function(v){
      return new Vec2(this.x + v.x, this.y + v.y);
    };
    prototype.sub = function(v){
      return new Vec2(this.x - v.x, this.y - v.y);
    };
    prototype.scale = function(s){
      return new Vec2(this.x * s, this.y * s);
    };
    prototype.length = function(){
      return Math.sqrt(this.squareLength());
    };
    prototype.squareLength = function(){
      return this.x * this.x + this.y * this.y;
    };
    prototype.normalized = function(){
      return this.scale(1.0 / this.length());
    };
    prototype.wrap = function(w, h){
      return new Vec2((this.x % w + w) % w, (this.y % h + h) % h);
    };
    prototype.toString = function(){
      return this.x + ", " + this.y;
    };
    return Vec2;
  }());
  Vec3 = (function(){
    Vec3.displayName = 'Vec3';
    var prototype = Vec3.prototype, constructor = Vec3;
    function Vec3(x, y, z){
      this.x = x;
      this.y = y;
      this.z = z;
    }
    prototype.add = function(v){
      return new Vec3(this.x + v.x, this.y + v.y, this.z + v.z);
    };
    prototype.sub = function(v){
      return new Vec3(this.x - v.x, this.y - v.y, this.z - v.z);
    };
    prototype.scale = function(s){
      return new Vec3(this.x * s, this.y * s, this.z * s);
    };
    prototype.length = function(){
      return Math.sqrt(this.squareLength());
    };
    prototype.squareLength = function(){
      return this.x * this.x + this.y * this.y + this.z * this.z;
    };
    prototype.normalized = function(){
      return this.scale(1.0 / this.length());
    };
    prototype.cross = function(v){
      return new Vec3(this.y * v.z - this.z * v.y, this.z * v.x - this.x * v.z, this.x * v.y - this.y * v.x);
    };
    prototype.dot = function(v){
      return this.x + v.x + this.y + v.y + this.z + v.z;
    };
    prototype.toString = function(){
      return this.x + ", " + this.y + ", " + this.z;
    };
    return Vec3;
  }());
  ref$ = out$;
  ref$.Vec2 = Vec2;
  ref$.Vec3 = Vec3;
}).call(this);

},{}],5:[function(require,module,exports){
(function(){
  var name, properties, create, ref$, out$ = typeof exports != 'undefined' && exports || this;
  name = "Gray";
  properties = {
    id: 'gamma',
    name: "Gamma",
    defaultValue: 1.0,
    range: [0, 100]
  };
  create = function(props, layer, view){
    var width, height, imgData, fb, gamma, code;
    width = layer.width;
    height = layer.height;
    imgData = view.imageData.data;
    fb = layer.getBuffer();
    gamma = props.gamma;
    code = "(function (rects) {'use strict';for(var ri in rects) {var r = rects[ri];var minX = r.x;var minY = r.y;var maxX = minX + r.width;var maxY = minY + r.height;for(var iy=minY; iy<=maxY; ++iy) {var offset = iy * width;for(var ix=minX; ix<=maxX; ++ix) {var fval = fb[offset + ix];fval = fval > 1.0 ? 1.0 : (fval < -1.0 ? -1.0 : fval);var val = Math.round(Math.pow((fval + 1.0) * 0.5, gamma) * 255.0) | 0;var off = (offset + ix) << 2;imgData[off] = val;imgData[off+1] = val;imgData[off+2] = val;imgData[off+3] = 0xff;}}view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);}});";
    return {
      render: eval(code)
    };
  };
  ref$ = out$;
  ref$.name = name;
  ref$.properties = properties;
  ref$.create = create;
}).call(this);

},{}],6:[function(require,module,exports){
(function(){
  var name, properties, create, ref$, out$ = typeof exports != 'undefined' && exports || this;
  name = "Gradient";
  properties = {
    id: 'gradient',
    name: "Gradient image",
    type: 'image'
  };
  create = function(props, layer, view){
    var width, height, imgData, fb, lut, code;
    width = layer.width;
    height = layer.height;
    imgData = view.imageData.data;
    fb = layer.getBuffer();
    lut = props.gradient.data;
    code = "(function (rects) {'use strict';for(var ri in rects) {var r = rects[ri];var minX = r.x;var minY = r.y;var maxX = minX + r.width;var maxY = minY + r.height;for(var iy=minY; iy<=maxY; ++iy) {var offset = iy * width;for(var ix=minX; ix<=maxX; ++ix) {var fval = fb[offset + ix];var lookupIndex = Math.round(Math.min(511,Math.max(0,256.0 * (1.0 + fval)))) * 4;var off = (offset + ix) << 2;imgData[off] =  lut[lookupIndex];imgData[off+1] = lut[lookupIndex+1];imgData[off+2] = lut[lookupIndex+2];imgData[off+3] = 0xff;}}view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);}});";
    return {
      render: eval(code)
    };
  };
  ref$ = out$;
  ref$.name = name;
  ref$.properties = properties;
  ref$.create = create;
}).call(this);

},{}],7:[function(require,module,exports){
(function(){
  var Core, Rect, Layer, Vec2, GammaRenderer, GradientRenderer, RoundBrush, loadGradient, testRenderers, testRoundBrush, testBlendModes, tests;
  Core = require('../core/core');
  Rect = require('../core/rect');
  Layer = require('../core/layer');
  Vec2 = require('../core/vec').Vec2;
  GammaRenderer = require('../renderers/gamma');
  GradientRenderer = require('../renderers/gradient');
  RoundBrush = require('../tools/roundbrush');
  loadGradient = function(url, done){
    var imageObj;
    imageObj = new Image();
    imageObj.onload = function(){
      var canvas, ctx, imageData;
      canvas = document.createElement("canvas");
      canvas.width = this.width;
      canvas.height = this.height;
      ctx = canvas.getContext('2d');
      ctx.drawImage(this, 0, 0);
      imageData = ctx.getImageData(0, 0, this.width, 1);
      return done(imageData);
    };
    return imageObj.src = url;
  };
  testRenderers = function($el){
    var width, height, renderTest;
    width = 800;
    height = 100;
    renderTest = function(type, props){
      var $can, layer, ctx, view, renderer;
      $can = $("<canvas width='" + width + "' height='" + height + "'/>").appendTo($el);
      layer = new Layer(width, height);
      layer.fill(function(x, y){
        if (y > 0) {
          return (Math.floor((x + 1) * 40) % 2 - Math.floor(y * 5) % 2) * (x + 1) / 2.0;
        } else {
          return x;
        }
      });
      ctx = $can[0].getContext('2d');
      view = {
        canvas: $can[0],
        context: ctx,
        imageData: ctx.getImageData(0, 0, width, height)
      };
      renderer = type.create(props, layer, view);
      renderer.render([new Rect(0, 0, width, height)]);
      return ctx.drawImage($can[0], 0, 0);
    };
    renderTest(GammaRenderer, {
      gamma: 0.1
    });
    renderTest(GammaRenderer, {
      gamma: 0.5
    });
    renderTest(GammaRenderer, {
      gamma: 1.0
    });
    renderTest(GammaRenderer, {
      gamma: 2.0
    });
    return loadGradient('/img/gradient-1.png', function(g1){
      return renderTest(GradientRenderer, {
        gradient: g1
      });
    });
  };
  testRoundBrush = function($el){
    var width, height, $can, layer, defaults, brushTest, x$, p, y, ctx, view, renderer;
    width = 800;
    height = 400;
    $can = $("<canvas width='" + width + "' height='" + height + "'/>").appendTo($el);
    layer = new Layer(width, height);
    layer.fill(function(x, y){
      return -1;
    });
    defaults = function(){
      var i$, ref$, len$, p, results$ = {};
      for (i$ = 0, len$ = (ref$ = RoundBrush.properties).length; i$ < len$; ++i$) {
        p = ref$[i$];
        results$[p.id] = p.defaultValue;
      }
      return results$;
    };
    brushTest = function(ypos, props){
      var f;
      f = function(xoffset, tiling){
        var env, brush, steps, i$, i, t, pos;
        env = {
          tiling: tiling,
          targetValue: 1.0
        };
        brush = RoundBrush.createTool(props, env);
        brush.beginDraw(layer, new Vec2(0, ypos));
        steps = 20;
        for (i$ = 0; i$ <= steps; ++i$) {
          i = i$;
          t = i / steps;
          pos = new Vec2(xoffset + t * 300, ypos - 30 * Math.sin(Math.PI * t));
          brush.draw(layer, pos, 1);
        }
        brush.endDraw();
      };
      f(50, false);
      f(450, true);
    };
    x$ = p = defaults();
    x$.hardness = 0;
    y = 0;
    brushTest(y += 50, p);
    p.size = 50;
    brushTest(y += 50, p);
    p.step = 30;
    brushTest(y += 50, p);
    p.step = 50;
    brushTest(y += 50, p);
    p.step = 30;
    p.hardness = 0.3;
    brushTest(y += 50, p);
    p.hardness = 0.5;
    brushTest(y += 50, p);
    p.hardness = 1.0;
    brushTest(y += 50, p);
    ctx = $can[0].getContext('2d');
    view = {
      canvas: $can[0],
      context: ctx,
      imageData: ctx.getImageData(0, 0, width, height)
    };
    renderer = GammaRenderer.create({
      gamma: 1
    }, layer, view);
    renderer.render([new Rect(0, 0, width, height)]);
    return ctx.drawImage($can[0], 0, 0);
  };
  testBlendModes = function($el){
    var width, height, $can, ctx, layer, brush, blendTest, view, renderer;
    width = 800;
    height = 400;
    $can = $("<canvas width='" + width + "' height='" + height + "'/>").appendTo($el);
    ctx = $can[0].getContext('2d');
    layer = new Layer(width, height);
    brush = new Layer(100, 100);
    brush.fill(Core.getRoundBrushFunc(0));
    layer.fill(function(x, y){
      x += 1;
      y += 1;
      return (Math.round(x * 80) % 2) * 0.1 - (Math.round(y * 40) % 2) * 0.1;
    });
    blendTest = function(y, args, expr){
      var fn, nsteps, i$, i, pressure, results$ = [];
      fn = Core.genBlendFunc(args, expr);
      nsteps = 30;
      for (i$ = 0; i$ < nsteps; ++i$) {
        i = i$;
        pressure = (1.0 - Math.cos(2 * Math.PI * i / nsteps)) * 0.5;
        results$.push(fn(new Vec2(i * width / nsteps - 50.0, y).round(), brush, layer, pressure));
      }
      return results$;
    };
    blendTest(0, "intensity", "{dst} += {src} * intensity");
    blendTest(100, "intensity", "{dst} *= 1 + {src} * intensity");
    blendTest(200, "intensity", "{dst} = {dst} * (1 - intensity*{src}) + 0.5 * intensity*{src}");
    blendTest(300, "intensity", "{dst} = {src} * intensity");
    view = {
      canvas: $can[0],
      context: ctx,
      imageData: ctx.getImageData(0, 0, width, height)
    };
    renderer = GammaRenderer.create({
      gamma: 1
    }, layer, view);
    renderer.render([new Rect(0, 0, width, height)]);
    return ctx.drawImage($can[0], 0, 0);
  };
  tests = [["Renderers", testRenderers]];
  (function(){
    var $root;
    $root = $('#tests-root');
    return tests.forEach(function(t){
      var $el;
      $('<h2>').text(t[0]).appendTo($root);
      $el = $('<div>').appendTo($root);
      $('<hr>').appendTo($root);
      return t[1]($el);
    });
  })();
}).call(this);

},{"../core/core":1,"../core/layer":2,"../core/rect":3,"../core/vec":4,"../renderers/gamma":5,"../renderers/gradient":6,"../tools/roundbrush":8}],8:[function(require,module,exports){
(function(){
  var Rect, genBrushFunc, createStepTool, name, properties, createTool, ref$, out$ = typeof exports != 'undefined' && exports || this;
  Rect = require('../core/rect');
  genBrushFunc = require('../core/core').genBrushFunc;
  createStepTool = require('./utils').createStepTool;
  name = "Round";
  properties = [
    {
      id: 'step',
      name: "Step %",
      defaultValue: 10,
      range: [0, 100]
    }, {
      id: 'hardness',
      name: "Hardness",
      defaultValue: 0.2,
      range: [0.0, 1.0]
    }, {
      id: 'size',
      name: "Size",
      defaultValue: 30.0,
      range: [1.0, 256.0],
      type: 'int'
    }, {
      id: 'blendMode',
      name: "Blend mode",
      defaultValue: "blend",
      choices: ["blend", "add", "sub", "multiply"]
    }, {
      id: 'intensity',
      name: "Intensity",
      defaultValue: 0.4,
      range: [0.0, 1.0],
      power: 2.0
    }
  ];
  createTool = function(props, env){
    var hardness, hardnessPlus1, intensity, size, func, drawFunc, stepOpts;
    hardness = Math.pow(props.hardness, 2.0) * 8.0;
    hardnessPlus1 = hardness + 1.0;
    intensity = props.intensity;
    size = props.size;
    func = genBrushFunc({
      args: "intensity, target, h, hp1",
      tiling: env.tiling,
      blendExp: "{dst} += {src} * intensity",
      brushExp: "var d = Math.min(1.0, Math.max(0.0, (Math.sqrt(x*x + y*y) * hp1 - h)));{out} = Math.cos(d * Math.PI) * 0.5 + 0.5;"
    });
    drawFunc = function(layer, pos, pressure, rect){
      var r;
      r = new Rect(pos.x - size * 0.5, pos.y - size * 0.5, size, size);
      func(r, layer, pressure * intensity, env.targetValue, hardness, hardnessPlus1);
      return rect.extend(r.round());
    };
    stepOpts = {
      step: Math.max(1, Math.round(props.step * props.size / 100.0)),
      tiling: env.tiling
    };
    return createStepTool(stepOpts, drawFunc);
  };
  ref$ = out$;
  ref$.name = name;
  ref$.properties = properties;
  ref$.createTool = createTool;
}).call(this);

},{"../core/core":1,"../core/rect":3,"./utils":9}],9:[function(require,module,exports){
(function(){
  var Rect, createStepTool, out$ = typeof exports != 'undefined' && exports || this;
  Rect = require('../core/rect');
  createStepTool = function(options, stepFunc){
    var step, tiling, lastpos, accumulator, draw, beginDraw, endDraw;
    step = options.step || 4.0;
    tiling = options.tiling || false;
    lastpos = null;
    accumulator = 0.0;
    draw = function(layer, pos, pressure){
      var wpos, rect, delt, length, dir, pt;
      wpos = tiling
        ? pos.wrap(layer.width, layer.height)
        : pos.clone();
      rect = new Rect(wpos.x, wpos.y, 1, 1);
      if (lastpos != null) {
        delt = pos.sub(lastpos);
        length = delt.length();
        dir = delt.scale(1.0 / length);
        while (accumulator + step <= length) {
          accumulator += step;
          pt = lastpos.add(dir.scale(accumulator));
          if (tiling) {
            pt = pt.wrap(layer.width, layer.height);
          }
          stepFunc(layer, pt, pressure, rect);
        }
        accumulator -= length;
      } else {
        stepFunc(layer, wpos, pressure, rect);
      }
      lastpos = pos.clone();
      return rect;
    };
    beginDraw = function(layer, pos){
      accumulator = 0;
    };
    endDraw = function(pos){
      lastpos = null;
    };
    return {
      draw: draw,
      beginDraw: beginDraw,
      endDraw: endDraw
    };
  };
  out$.createStepTool = createStepTool;
}).call(this);

},{"../core/rect":3}]},{},[7])