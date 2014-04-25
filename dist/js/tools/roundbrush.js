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
