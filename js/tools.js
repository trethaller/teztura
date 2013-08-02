// Generated by CoffeeScript 1.6.3
var BlendModes, Picker, RoundBrush, StepBrush;

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

  StepBrush.prototype.beginDraw = function() {
    this.drawing = true;
    this.accumulator = 0;
    return this.nsteps = 0;
  };

  StepBrush.prototype.endDraw = function() {
    this.lastpos = null;
    this.drawing = false;
    return console.log("" + this.nsteps + " steps drawn");
  };

  return StepBrush;

})();

BlendModes = {
  add: "{dst} += {src} * intensity",
  sub: "{dst} -= {src} * intensity",
  multiply: "{dst} *= 1 + {src} * intensity",
  blend: "{dst} = {dst} * (1 - intensity * {src}) + intensity * target * {src}"
};

Picker = (function() {
  return {
    description: {
      name: 'Picker'
    },
    properties: {},
    createTool: function(env) {
      return {
        beginDraw: function() {},
        endDraw: function() {},
        move: function() {},
        draw: function(layer, pos, intensity) {
          env.targetValue = layer.getAt(pos);
          return Rect.Empty;
        }
      };
    }
  };
})();

RoundBrush = (function() {
  var createTool, description, properties;
  description = {
    name: 'Round'
  };
  properties = {
    stepSize: {
      name: "Step size",
      value: 4,
      range: [1, 20]
    },
    hardness: {
      name: "Hardness",
      value: 1.0,
      range: [0.0, 10.0]
    },
    size: {
      name: "Size",
      value: 40.0,
      range: [1.0, 256.0]
    },
    blendMode: {
      name: "Blend mode",
      value: "blend",
      choices: ["blend", "add", "sub", "multiply"]
    },
    intensity: {
      name: "Intensity",
      value: 0.1,
      range: [0.0, 1.0]
    }
  };
  createTool = function(env) {
    var func, hardness, hardnessPlus1, rad, sb;
    sb = new StepBrush();
    sb.stepSize = properties.stepSize.value;
    rad = properties.size.value;
    hardness = properties.hardness.value;
    hardnessPlus1 = hardness + 1.0;
    func = genBrushFunc("intensity, target, h, hp1", "var d = Math.min(1.0, Math.max(0.0, (Math.sqrt(x*x + y*y) * hp1 - h)));      {out} = Math.cos(d * Math.PI) * 0.5 + 0.5;", BlendModes[properties.blendMode.value]);
    sb.drawStep = function(layer, pos, intensity, rect) {
      var r;
      r = new Rect(pos.x - rad * 0.5, pos.y - rad * 0.5, rad, rad).round();
      func(r, layer, intensity * properties.intensity.value, env.targetValue, hardness, hardnessPlus1);
      return rect.extend(r);
    };
    return sb;
  };
  return {
    description: description,
    properties: properties,
    createTool: createTool
  };
})();
