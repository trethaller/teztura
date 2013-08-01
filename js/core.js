// Generated by CoffeeScript 1.6.3
var Bezier, Brush, FloatBuffer, GammaRenderer, Layer, Rect, StepBrush, Vector, genBlendFunc, genKernelFunc, getRoundBrushFunc;

Vector = (function() {
  function Vector(x, y) {
    this.x = x;
    this.y = y;
  }

  Vector.prototype.distanceTo = function(v) {
    return Math.sqrt(squareDistanceTo(v));
  };

  Vector.prototype.squareDistanceTo = function(v) {
    var dx, dy;
    dx = this.x - v.x;
    dy = this.y - v.y;
    return dx * dx + dy * dy;
  };

  Vector.prototype.round = function() {
    return new Vector(Math.round(this.x), Math.round(this.y));
  };

  Vector.prototype.add = function(v) {
    return new Vector(this.x + v.x, this.y + v.y);
  };

  Vector.prototype.sub = function(v) {
    return new Vector(this.x - v.x, this.y - v.y);
  };

  Vector.prototype.scale = function(s) {
    return new Vector(this.x * s, this.y * s);
  };

  Vector.prototype.length = function() {
    return Math.sqrt(this.squareLength());
  };

  Vector.prototype.squareLength = function() {
    return this.x * this.x + this.y * this.y;
  };

  Vector.prototype.normalized = function() {
    return this.scale(1.0 / this.length());
  };

  return Vector;

})();

Rect = (function() {
  function Rect(x, y, width, height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  Rect.prototype.intersect = function(rect) {
    var nmaxx, nmaxy, nx, ny;
    nmaxx = Math.min(this.x + this.width, rect.x + rect.width);
    nmaxy = Math.min(this.y + this.height, rect.y + rect.height);
    nx = Math.max(this.x, rect.x);
    ny = Math.max(this.y, rect.y);
    return new Rect(nx, ny, Math.max(0, nmaxx - nx), Math.max(0, nmaxy - ny));
  };

  Rect.prototype.union = function(rect) {
    var ret;
    ret = new Rect(this.x, this.y, this.width, this.height);
    ret.extend(rect.topLeft());
    ret.extend(rect.bottomRight());
    return ret;
  };

  Rect.prototype.empty = function() {
    return this.width <= 0 || this.height <= 0;
  };

  Rect.prototype.round = function() {
    return new Rect(Math.floor(this.x), Math.floor(this.y), Math.ceil(this.width), Math.ceil(this.height));
  };

  Rect.prototype.extend = function(obj) {
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

  Rect.prototype.topLeft = function() {
    return new Vector(this.x, this.y);
  };

  Rect.prototype.bottomRight = function() {
    return new Vector(this.x + this.width, this.y + this.height);
  };

  return Rect;

})();

FloatBuffer = (function() {
  function FloatBuffer(width, height) {
    this.width = width;
    this.height = height;
    this.buffer = new ArrayBuffer(this.width * this.height * 4);
    this.fbuffer = new Float32Array(this.buffer);
  }

  return FloatBuffer;

})();

Layer = (function() {
  function Layer(width, height) {
    this.width = width;
    this.height = height;
    this.data = new FloatBuffer(this.width, this.height);
  }

  Layer.prototype.getRect = function() {
    return new Rect(0, 0, this.width, this.height);
  };

  Layer.prototype.getBuffer = function() {
    return this.data.fbuffer;
  };

  return Layer;

})();

Bezier = {
  quadratic: function(pts, t) {
    var f2, f3, lerp;
    lerp = function(a, b, t) {
      return a * t + b * (1 - t);
    };
    f3 = function(v1, v2, v3, t) {
      return lerp(lerp(v1, v2, t), lerp(v2, v3, t), t);
    };
    f2 = function(v1, v2, t) {
      return lerp(v1, v2, t);
    };
    if (pts.length === 1) {
      return pts[0];
    } else if (pts.length === 2) {
      return new Vector(f2(pts[0].x, pts[1].x, t), f2(pts[0].y, pts[1].y, t));
    } else {
      return new Vector(f3(pts[0].x, pts[1].x, pts[2].x, t), f3(pts[0].y, pts[1].y, pts[2].y, t));
    }
  }
};

Brush = (function() {
  function Brush() {}

  Brush.prototype.stroke = function(layer, start, end, pressure) {};

  Brush.prototype.move = function(pos, intensity) {};

  Brush.prototype.beginStroke = function(pos) {};

  Brush.prototype.endStroke = function(pos) {};

  return Brush;

})();

StepBrush = (function() {
  function StepBrush() {}

  StepBrush.prototype.drawing = false;

  StepBrush.prototype.lastpos = null;

  StepBrush.prototype.accumulator = 0.0;

  StepBrush.prototype.stepSize = 4.0;

  StepBrush.prototype.nsteps = 0;

  StepBrush.prototype.drawStep = function(layer, pos, intensity, rect) {
    var fb;
    fb = layer.getBuffer();
    fb[Math.floor(pos.x) + Math.floor(pos.y) * layer.width] = intensity;
    return rect.extend(pos);
  };

  StepBrush.prototype.move = function(pos, intensity) {};

  StepBrush.prototype.draw = function(layer, pos, intensity) {
    var delt, dir, length, pt, rect;
    rect = new Rect(pos.x, pos.y, 1, 1);
    if (this.lastpos != null) {
      delt = pos.sub(this.lastpos);
      length = delt.length();
      dir = delt.scale(1.0 / length);
      while (this.accumulator + this.stepSize <= length) {
        this.accumulator += this.stepSize;
        pt = this.lastpos.add(dir.scale(this.accumulator));
        this.drawStep(layer, pt, intensity, rect);
        ++this.nsteps;
      }
      this.accumulator -= length;
    } else {
      this.drawStep(layer, pos, intensity, rect);
      ++this.nsteps;
    }
    this.lastpos = pos;
    return rect;
  };

  StepBrush.prototype.beginStroke = function() {
    this.drawing = true;
    this.accumulator = 0;
    return this.nsteps = 0;
  };

  StepBrush.prototype.endStroke = function() {
    this.lastpos = null;
    this.drawing = false;
    return console.log("" + this.nsteps + " steps drawn");
  };

  return StepBrush;

})();

GammaRenderer = (function() {
  var properties;
  properties = {
    gamma: 1.0
  };
  function renderLayer (layer, view, rects) {
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
  };
  return {
    properties: properties,
    renderLayer: renderLayer
  };
})();


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
;

genBlendFunc = function(args, expression) {
  var expr, str;
  expr = expression.replace(/{dst}/g, "dstData[dsti]").replace(/{src}/g, "srcData[srci]");
  str = "    (function (pos, srcFb, dstFb, " + args + ") {      var minx = Math.max(0, -pos.x);      var miny = Math.max(0, -pos.y);      var sw = Math.min(srcFb.width, dstFb.width - pos.x);      var sh = Math.min(srcFb.height, dstFb.height - pos.y);      var srcData = srcFb.getBuffer();      var dstData = dstFb.getBuffer();      for(var sy=miny; sy<sh; ++sy) {        var srci = sy * srcFb.width + minx;        var dsti = (pos.y + sy) * dstFb.width + pos.x + minx;        for(var sx=minx; sx<sw; ++sx) {          " + expr + ";          ++dsti;          ++srci;        }      }    })";
  return eval(str);
};

genKernelFunc = function(args, expression) {
  var expr, str;
  expr = expression.replace(/{dst}/g, "dstData[dsti]");
  str = "    (function (rect, dstFb, " + args + ") {      var minx = Math.max(0, -rect.x);      var miny = Math.max(0, -rect.y);      var sw = Math.min(rect.width, dstFb.width - rect.x);      var sh = Math.min(rect.height, dstFb.height - rect.y);      var invw = 2.0 / (rect.width - 1);      var invh = 2.0 / (rect.height - 1);      var dstData = dstFb.getBuffer();      for(var sy=miny; sy<sh; ++sy) {        var dsti = (pos.y + sy) * dstFb.width + pos.x + minx;        var y = sy * invh - 1.0;        for(var sx=minx; sx<sw; ++sx) {          var x = sx * invw - 1.0;          " + expr + ";          ++dsti;        }      }    })";
  return eval(str);
};

getRoundBrushFunc = function(hardness) {
  var hardnessPlus1;
  hardnessPlus1 = hardness + 1.0;
  return function(x, y) {
    var d;
    d = Math.min(1.0, Math.max(0.0, Math.sqrt(x * x + y * y) * hardnessPlus1 - hardness));
    return Math.cos(d * Math.PI) * 0.5 + 0.5;
  };
};

if (typeof module !== "undefined" && module !== null) {
  module.exports = {
    Vector: Vector,
    Rect: Rect,
    FloatBuffer: FloatBuffer,
    Layer: Layer
  };
}
