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

},{"../core/rect":4}],3:[function(require,module,exports){
(function(){
  var createProperties, out$ = typeof exports != 'undefined' && exports || this;
  createProperties = function(target, definitions, changed){
    target.properties = [];
    return definitions.forEach(function(def){
      var prop;
      prop = clone$(def);
      prop.value = ko.observable(def.defaultValue);
      if (changed != null) {
        prop.value.subscribe(function(val){
          return changed(prop.id, val);
        });
      }
      target[prop.id] = prop.value;
      return target.properties.push(prop);
    });
  };
  out$.createProperties = createProperties;
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
}).call(this);

},{}],4:[function(require,module,exports){
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

},{"./vec":6}],5:[function(require,module,exports){
(function(){
  var loadImageData, out$ = typeof exports != 'undefined' && exports || this;
  loadImageData = function(url, done){
    var imageObj;
    imageObj = new Image();
    imageObj.onload = function(){
      var canvas, ctx, imageData;
      canvas = document.createElement("canvas");
      canvas.width = this.width;
      canvas.height = this.height;
      ctx = canvas.getContext('2d');
      ctx.drawImage(this, 0, 0);
      imageData = ctx.getImageData(0, 0, this.width, this.height);
      return done(imageData);
    };
    imageObj.src = url;
  };
  out$.loadImageData = loadImageData;
}).call(this);

},{}],6:[function(require,module,exports){
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

},{}],7:[function(require,module,exports){
(function(){
  var Vec2, Rect, GammaRenderer, DocumentView;
  Vec2 = require('./core/vec').Vec2;
  Rect = require('./core/rect');
  GammaRenderer = require('./renderers/gamma');
  DocumentView = (function(){
    DocumentView.displayName = 'DocumentView';
    var prototype = DocumentView.prototype, constructor = DocumentView;
    prototype.drawing = false;
    prototype.panning = false;
    prototype.imageData = null;
    prototype.context = null;
    prototype.canvas = null;
    prototype.backContext = null;
    prototype.doc = null;
    prototype.offset = new Vec2(0.0, 0.0);
    prototype.scale = 2.0;
    prototype.penPos = new Vec2(0, 0);
    function DocumentView($container, doc, editor){
      var $canvas, $backCanvas, plugin, penAPI, getMouseCoords, getPressure, updatePen, getCanvasCoords, this$ = this;
      this.doc = doc;
      this.editor = editor;
      $container.empty();
      $canvas = $('<canvas/>', {
        'class': ''
      }).attr({
        width: this.doc.width,
        height: this.doc.height
      });
      $backCanvas = $('<canvas/>', {
        'class': ''
      }).attr({
        width: this.doc.width,
        height: this.doc.height
      });
      $container.append($backCanvas);
      this.backContext = $backCanvas[0].getContext('2d');
      this.canvas = $canvas[0];
      this.context = $canvas[0].getContext('2d');
      this.imageData = this.context.getImageData(0, 0, this.doc.width, this.doc.height);
      this.context.mozImageSmoothingEnabled = false;
      this.renderer = null;
      plugin = document.getElementById('wtPlugin');
      penAPI = plugin != null ? plugin.penAPI : void 8;
      getMouseCoords = function(e){
        var v;
        v = new Vec2(e.pageX, e.pageY);
        /*
        penAPI = plugin.penAPI
        if penAPI? and penAPI.pointerType > 0
          v.x += penAPI.sysX - penAPI.posX
          v.y += penAPI.sysY - penAPI.posY
        */
        v.x -= $backCanvas.position().left;
        v.y -= $backCanvas.position().top;
        return v;
      };
      getPressure = function(){
        if ((penAPI != null ? penAPI.pointerType : void 8) > 0) {
          return penAPI.pressure;
        }
        return 1.0;
      };
      updatePen = function(e){
        var pos;
        pos = getMouseCoords(e);
        this$.penPos = this$.penPos.add(pos.sub(this$.penPos).scale(0.6));
      };
      getCanvasCoords = function(){
        return this$.screenToCanvas(this$.penPos);
      };
      $backCanvas.mousedown(function(e){
        var coords;
        e.preventDefault();
        if (e.which === 1) {
          this$.drawing = true;
          this$.actionDirtyRect = null;
          coords = getCanvasCoords();
          this$.editor.toolObject().beginDraw(this$.doc.layer, coords);
          this$.doc.beginEdit();
          this$.onDraw(coords, getPressure());
        }
        if (e.which === 2) {
          this$.panning = true;
          this$.panningStart = getMouseCoords(e);
          return this$.offsetStart = this$.offset.clone();
        }
      });
      $container.mouseup(function(e){
        e.preventDefault();
        if (e.which === 1) {
          this$.editor.toolObject().endDraw(getCanvasCoords());
          this$.drawing = false;
          if (this$.actionDirtyRect != null) {
            this$.doc.afterEdit(this$.actionDirtyRect);
          }
        }
        if (e.which === 2) {
          return this$.panning = false;
        }
      });
      $container.mousemove(function(e){
        var curPos, o;
        e.preventDefault();
        updatePen(e);
        if (this$.drawing) {
          this$.onDraw(getCanvasCoords(), getPressure());
        }
        if (this$.panning) {
          curPos = getMouseCoords(e);
          o = this$.offsetStart.add(curPos.sub(this$.panningStart));
          this$.offset = o;
          return this$.repaint();
        }
      });
      $container.mousewheel(function(e, delta, deltaX, deltaY){
        var mult;
        mult = 1.0 + deltaY * 0.25;
        this$.scale *= mult;
        return this$.repaint();
      });
    }
    prototype.screenToCanvas = function(pt){
      return pt.sub(this.offset).scale(1.0 / this.scale);
    };
    prototype.render = function(){
      var ref$;
      if ((ref$ = this.renderer) != null) {
        ref$.render([new Rect(0, 0, this.doc.width, this.doc.height)]);
      }
      return this.repaint();
    };
    prototype.repaint = function(){
      var x$, ctx;
      x$ = ctx = this.backContext;
      x$.setTransform(1, 0, 0, 1, 0, 0);
      x$.translate(this.offset.x, this.offset.y);
      x$.scale(this.scale, this.scale);
      if (this.editor.tiling()) {
        ctx.fillStyle = ctx.createPattern(this.canvas, "repeat");
        return ctx.fillRect(-this.offset.x / this.scale, -this.offset.y / this.scale, this.canvas.width / this.scale, this.canvas.height / this.scale);
      } else {
        return ctx.drawImage(this.canvas, 0, 0);
      }
    };
    prototype.onDraw = function(pos, pressure){
      var dirtyRects, layer, tool, layerRect, r, i$, ref$, len$, xoff, j$, ref1$, len1$, yoff, totalArea, this$ = this;
      dirtyRects = [];
      layer = this.doc.layer;
      tool = this.editor.toolObject();
      layerRect = layer.getRect();
      r = tool.draw(layer, pos, pressure).round();
      if (this.editor.tiling()) {
        for (i$ = 0, len$ = (ref$ = [-1, 0, 1]).length; i$ < len$; ++i$) {
          xoff = ref$[i$];
          for (j$ = 0, len1$ = (ref1$ = [-1, 0, 1]).length; j$ < len1$; ++j$) {
            yoff = ref1$[j$];
            dirtyRects.push(r.offset(new Vec2(xoff * layerRect.width, yoff * layerRect.height)));
          }
        }
      } else {
        dirtyRects.push(r.intersect(layerRect));
      }
      dirtyRects = dirtyRects.map(function(r){
        return r.intersect(layerRect);
      }).filter(function(r){
        return !r.isEmpty();
      });
      dirtyRects.forEach(function(r){
        if (this$.actionDirtyRect == null) {
          return this$.actionDirtyRect = r.clone();
        } else {
          return this$.actionDirtyRect.extend(r);
        }
      });
      if (false) {
        totalArea = dirtyRects.map(function(r){
          return r.width * r.height;
        }).reduce(function(a, b){
          return a + b;
        });
        console.log(dirtyRects.length + " rects, " + Math.round(Math.sqrt(totalArea)) + " px²");
      }
      if (true) {
        if ((ref$ = this.renderer) != null) {
          ref$.render(dirtyRects);
        }
        return this.repaint();
      }
    };
    return DocumentView;
  }());
  module.exports = DocumentView;
}).call(this);

},{"./core/rect":4,"./core/vec":6,"./renderers/gamma":11}],8:[function(require,module,exports){
(function(){
  var Layer, Document;
  Layer = require('./core/layer');
  Document = (function(){
    Document.displayName = 'Document';
    var prototype = Document.prototype, constructor = Document;
    function Document(width, height){
      this.width = width;
      this.height = height;
      this.layer = new Layer(this.width, this.height);
      this.backup = new Layer(this.width, this.height);
      this.history = [];
      this.histIndex = 1;
    }
    prototype.beginEdit = function(){
      if (this.histIndex > 0) {
        this.history.splice(0, this.histIndex);
        this.histIndex = 0;
        return this.backup.getBuffer().set(this.layer.getBuffer());
      }
    };
    prototype.afterEdit = function(rect){
      var histSize;
      this.history.splice(0, 0, {
        data: this.backup.getCopy(rect),
        rect: rect
      });
      this.backup.getBuffer().set(this.layer.getBuffer());
      histSize = 10;
      if (this.history.length >= histSize) {
        return this.history.splice(histSize);
      }
    };
    prototype.undo = function(){
      if (this.histIndex >= this.history.length) {
        return;
      }
      this.restore();
      return this.histIndex++;
    };
    prototype.redo = function(){
      if (this.histIndex === 0) {
        return;
      }
      this.histIndex--;
      return this.restore();
    };
    prototype.restore = function(){
      var toRestore, rect;
      toRestore = this.history[this.histIndex];
      rect = toRestore.rect;
      this.history[this.histIndex] = {
        data: this.layer.getCopy(rect),
        rect: rect
      };
      return this.layer.setData(toRestore.data, toRestore.rect);
    };
    return Document;
  }());
  module.exports = Document;
}).call(this);

},{"./core/layer":2}],9:[function(require,module,exports){
(function(){
  var loadImageData, Document, DocumentView, RoundBrush, GradientRenderer, GammaRenderer, PropertyGroup, ListView, Editor, start;
  loadImageData = require('./core/utils').loadImageData;
  Document = require('./document');
  DocumentView = require('./document-view');
  RoundBrush = require('./tools/roundbrush');
  GradientRenderer = require('./renderers/gradient');
  GammaRenderer = require('./renderers/gamma');
  PropertyGroup = require('./property-view').PropertyGroup;
  ListView = function(choices){};
  Editor = function(){
    var res$, i$, ref$, len$, t, x$, toolProps, y$, renderProps, this$ = this;
    this.tiling = function(){
      return true;
    };
    this.tool = new RoundBrush(this);
    this.toolObject = function(){
      return this.tool;
    };
    this.doc = new Document(512, 512);
    this.doc.layer.fill(function(){
      return -1;
    });
    this.view = new DocumentView($('.document-view'), this.doc, this);
    res$ = [];
    for (i$ = 0, len$ = (ref$ = [GammaRenderer, GradientRenderer]).length; i$ < len$; ++i$) {
      t = ref$[i$];
      res$.push(new t(this.doc.layer, this.view));
    }
    this.renderers = res$;
    this.renderer = ko.observable(this.renderers[1]);
    this.renderer.subscribe(function(r){
      this$.view.renderer = r;
      this$.view.render();
      return renderProps.setProperties(r.properties);
    });
    x$ = toolProps = new PropertyGroup('Tool');
    x$.setProperties(this.tool.properties);
    x$.$el.appendTo($('#properties'));
    y$ = renderProps = new PropertyGroup('Tool');
    y$.setProperties(this.renderer().properties);
    y$.$el.appendTo($('#properties'));
    this.renderer(this.renderers[0]);
  };
  start = function(){
    var editor;
    editor = new Editor;
    return ko.applyBindings(editor, $('#editor')[0]);
  };
  $(document).ready(start);
}).call(this);

},{"./core/utils":5,"./document":8,"./document-view":7,"./property-view":10,"./renderers/gamma":11,"./renderers/gradient":12,"./tools/roundbrush":13}],10:[function(require,module,exports){
(function(){
  var Vec2, loadImageData, makeDraggable, SliderView, SliderPropertyView, ImagePropertyView, PropertyView, PropertyGroup, out$ = typeof exports != 'undefined' && exports || this;
  Vec2 = require('./core/vec').Vec2;
  loadImageData = require('./core/utils').loadImageData;
  makeDraggable = function(el){
    function DragHelper(el){
      var evtPos, onMouseUp, onMouseMove, startDrag, stopDrag, this$ = this;
      this.el = el;
      this.startPos = null;
      this.lastPos = null;
      this.delta = null;
      this.cleanup = function(){
        stopDrag();
        return this.el.off('mousedown', startDrag);
      };
      evtPos = function(e){
        return new Vec2(e.clientX, e.clientY);
      };
      onMouseUp = function(){
        return stopDrag();
      };
      onMouseMove = function(e){
        var pos, delta;
        pos = evtPos(e);
        delta = pos.sub(this$.lastPos);
        this$.el.trigger('drag', [delta.x, delta.y]);
        return this$.lastPos = pos;
      };
      startDrag = function(e){
        var p;
        this$.startPos = evtPos(e);
        $(document).on('mouseup', onMouseUp);
        $(document).on('mousemove', onMouseMove);
        p = this$.lastPos = this$.startPos;
        return this$.el.trigger('drag', [0, 0]);
      };
      stopDrag = function(){
        if (this$.startPos != null) {
          this$.startPos = null;
          this$.lastPos = null;
          $(document).off('mouseup', onMouseUp);
          return $(document).off('mousemove', onMouseMove);
        }
      };
      return this.el.on('mousedown', startDrag);
    }
    return new DragHelper(el);
  };
  SliderView = function(){
    var drag, this$ = this;
    this.el = $('<span/>').addClass('tz-slider');
    this.bar = $('<span/>').addClass('tz-slider-bar').appendTo(this.el);
    this.setValue = function(v){
      return this$.bar.width(v * 100 + '%');
    };
    drag = makeDraggable(this.el);
    this.cleanup = function(){
      return drag.cleanup();
    };
    this.bar.width('50%');
  };
  SliderPropertyView = function($el, prop){
    var power, conv, invconv, rmin, rmax, range, sv, subscription, $input, this$ = this;
    power = prop.power || 1.0;
    conv = function(v){
      return Math.pow(v, power);
    };
    invconv = function(v){
      return Math.pow(v, 1.0 / power);
    };
    rmin = invconv(prop.range[0]);
    rmax = invconv(prop.range[1]);
    range = prop.range[1] - prop.range[0];
    sv = new SliderView();
    sv.setValue(invconv(prop.value() / range));
    sv.el.appendTo($el);
    sv.el.on('drag', function(e, x, y){
      prop.value(conv(invconv(prop.value()) + x * range / 500));
    });
    subscription = prop.value.subscribe(function(newVal){
      $input.val(newVal);
      sv.setValue(invconv(newVal / range));
    });
    $input = $('<input/>').val(prop.value()).appendTo($el).addClass('tz-input').change(function(evt){
      if (prop.type === 'int') {
        return prop.value(parseInt($input.val()));
      } else {
        return prop.value(parseFloat($input.val()));
      }
    });
    this.cleanup = function(){
      return subscription.dispose();
    };
  };
  ImagePropertyView = function($el, prop){
    var $select, this$ = this;
    $select = $('<select/>').appendTo($el).change(function(e){
      return loadImageData($select.val(), function(img){
        return prop.value(img);
      });
    });
    prop.choices.forEach(function(c){
      var $op;
      return $op = $('<option/>').text(c).appendTo($select);
    });
    this.cleanup = function(){};
  };
  PropertyView = function(prop){
    var $prop, pv, this$ = this;
    this.$el = $('<div/>').addClass('property');
    $('<label/>').text(prop.name).appendTo(this.$el);
    $prop = $('<div/>').appendTo(this.$el);
    pv = null;
    if (prop.range != null) {
      pv = new SliderPropertyView($prop, prop);
    } else if (prop.type === 'gradient') {
      pv = new ImagePropertyView($prop, prop);
    }
    this.cleanup = function(){
      if (pv != null) {
        pv.cleanup();
      }
    };
  };
  PropertyGroup = function(title){
    var this$ = this;
    this.$el = $('<div/>').addClass('property-group');
    this.setProperties = function(props){
      this$.$el.empty();
      $('<h1/>').text(title).appendTo(this$.$el);
      props.forEach(function(p){
        var pv;
        pv = new PropertyView(p);
        this$.$el.append(pv.$el);
      });
    };
  };
  out$.PropertyGroup = PropertyGroup;
}).call(this);

},{"./core/utils":5,"./core/vec":6}],11:[function(require,module,exports){
(function(){
  var createProperties, GammaRenderer;
  createProperties = require('../core/properties').createProperties;
  GammaRenderer = function(layer, view){
    var generateFunc, this$ = this;
    createProperties(this, [{
      id: 'gamma',
      name: "Gamma",
      defaultValue: 1.0,
      range: [0, 10]
    }], propChanged);
    this.name = "Gamma";
    function propChanged(pid, val, prev){
      this$.renderFunc = null;
      return view.render();
    }
    generateFunc = function(){
      var width, height, imgData, fb, gamma, code;
      width = layer.width;
      height = layer.height;
      imgData = view.imageData.data;
      fb = layer.getBuffer();
      gamma = this$.gamma();
      code = "(function (rects) {'use strict';for(var ri in rects) {var r = rects[ri];var minX = r.x;var minY = r.y;var maxX = minX + r.width;var maxY = minY + r.height;for(var iy=minY; iy<=maxY; ++iy) {var offset = iy * " + width + ";for(var ix=minX; ix<=maxX; ++ix) {var fval = fb[offset + ix];fval = fval > 1.0 ? 1.0 : (fval < -1.0 ? -1.0 : fval);var val = Math.round(Math.pow((fval + 1.0) * 0.5, " + gamma + ") * 255.0) | 0;var off = (offset + ix) << 2;imgData[off] = val;imgData[off+1] = val;imgData[off+2] = val;imgData[off+3] = 0xff;}}view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);}});";
      return eval(code);
    };
    this.render = function(rects){
      if (this$.renderFunc == null) {
        this$.renderFunc = generateFunc();
      }
      this$.renderFunc(rects);
    };
  };
  module.exports = GammaRenderer;
}).call(this);

},{"../core/properties":3}],12:[function(require,module,exports){
(function(){
  var createProperties, GradientRenderer;
  createProperties = require('../core/properties').createProperties;
  GradientRenderer = function(layer, view){
    var generateFunc, this$ = this;
    createProperties(this, [{
      id: 'gradient',
      name: "Gradient image",
      type: 'gradient',
      choices: ['img/gradient-1.png', 'img/gradient-2.png']
    }], propChanged);
    this.name = "Gradient";
    function propChanged(pid, val, prev){
      this$.renderFunc = null;
      return view.render();
    }
    generateFunc = function(){
      var width, imgData, fb, lutImg, lut, round, norm, clamp, code;
      width = layer.width;
      imgData = view.imageData.data;
      fb = layer.getBuffer();
      lutImg = this$.gradient();
      if (lutImg == null) {
        return function(){};
      }
      lut = lutImg.data;
      round = function(val){
        return "(" + val + " + 0.5) | 0";
      };
      norm = function(val){
        return lutImg.width / 2 + ".0 * (1.0 + " + val + ")";
      };
      clamp = function(val){
        return val + " < 0 ? 0 : (" + val + " > " + (lutImg.width - 1) + " ? " + (lutImg.width - 1) + " : " + val + ")";
      };
      code = "(function (rects) {'use strict';for(var ri in rects) {var r = rects[ri];var minX = r.x | 0;var minY = r.y | 0;var maxX = minX + r.width | 0;var maxY = minY + r.height | 0;for(var iy=minY; iy<=maxY; ++iy) {var offset = iy * " + width + ";for(var ix=minX; ix<=maxX; ++ix) {var fval = " + round(norm('fb[offset + ix]')) + ";var lookupIndex = (" + clamp('fval') + ") << 2;var off = (offset + ix) << 2;imgData[off] =   lut[lookupIndex];imgData[++off] = lut[++lookupIndex];imgData[++off] = lut[++lookupIndex];imgData[++off] = 0xff;}}view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);}});";
      console.log(code);
      return eval(code);
    };
    this.render = function(rects){
      if (this$.renderFunc == null) {
        this$.renderFunc = generateFunc();
      }
      this$.renderFunc(rects);
    };
  };
  module.exports = GradientRenderer;
}).call(this);

},{"../core/properties":3}],13:[function(require,module,exports){
(function(){
  var createStepTool, Rect, genBrushFunc, createProperties, RoundBrush;
  createStepTool = require('./utils').createStepTool;
  Rect = require('../core/rect');
  genBrushFunc = require('../core/core').genBrushFunc;
  createProperties = require('../core/properties').createProperties;
  RoundBrush = function(env){
    var properties, this$ = this;
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
    this.tool = null;
    createProperties(this, properties, propChanged);
    function propChanged(pid, val, prev){
      return this$.tool = null;
    }
    function createTool(){
      var hardness, intensity, size, func, drawFunc, stepOpts;
      hardness = Math.pow(this$.hardness(), 2.0) * 8.0;
      intensity = this$.intensity();
      size = this$.size();
      func = genBrushFunc({
        args: "intensity, target, h",
        tiling: env.tiling,
        blendExp: "{dst} += {src} * intensity",
        brushExp: "var d = Math.min(1.0, Math.max(0.0, (Math.sqrt(x*x + y*y) * (h+1) - h)));{out} = Math.cos(d * Math.PI) * 0.5 + 0.5;"
      });
      drawFunc = function(layer, pos, pressure, rect){
        var r;
        r = new Rect(pos.x - size * 0.5, pos.y - size * 0.5, size, size);
        func(r, layer, pressure * intensity, env.targetValue, hardness);
        return rect.extend(r.round());
      };
      stepOpts = {
        step: Math.max(1, Math.round(this$.step() * this$.size() / 100.0)),
        tiling: env.tiling
      };
      return createStepTool(stepOpts, drawFunc);
    }
    function getTool(){
      if (this$.tool == null) {
        this$.tool = createTool();
      }
      return this$.tool;
    }
    this.beginDraw = function(){};
    this.draw = function(){
      return getTool().draw.apply(this$, arguments);
    };
    this.endDraw = function(){
      return getTool().endDraw.apply(this$, arguments);
    };
  };
  module.exports = RoundBrush;
}).call(this);

},{"../core/core":1,"../core/properties":3,"../core/rect":4,"./utils":14}],14:[function(require,module,exports){
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

},{"../core/rect":4}]},{},[9])