# {createStepTool}    = require './utils'
Rect                = require '../core/rect'
{genBrushFunc}      = require '../core/core'
{createProperties}  = require '../core/properties'


RoundBrush = (env) !->
  properties = 
    * id: 'step'
      name: "Step %"
      defaultValue: 10
      range: [0, 100]
    
    * id: 'hardness'
      name: "Hardness"
      defaultValue: 0.2
      range: [0.0, 1.0]
    
    * id: 'size'
      name: "Size"
      defaultValue: 30.0
      range: [1.0, 256.0]
      type: 'int'
    
    * id: 'blendMode'
      name: "Blend mode"
      defaultValue: "blend"
      choices: ["blend", "add", "sub", "multiply"]
    
    * id:'intensity'
      name: "Intensity"
      defaultValue: 0.4
      range: [0.0, 1.0]
      power: 2.0

  @func = null
  createProperties @, properties

  @propertyChanged.subscribe ~>
    @func = null
  
  ~function genFunc
    hardness = Math.pow(@hardness!, 2.0) * 8.0;
    intensity = @intensity!
    size = @size!

    bf = genBrushFunc {
      args: "intensity, target, h"
      tiling: env.tiling
      blendExp: "{dst} += {src} * intensity"
      brushExp: "var d = Math.min(1.0, Math.max(0.0, (Math.sqrt(x*x + y*y) * (h+1) - h)));
                {out} = Math.cos(d * Math.PI) * 0.5 + 0.5;"
    }

    return (layer, pos, pressure) ~>
      r = new Rect(
        pos.x - size * 0.5,
        pos.y - size * 0.5,
        size, size)
      bf(r, layer, pressure * intensity, env.targetValue, hardness)
      return r

    /*

    stepOpts = 
      step: Math.max(1, Math.round(@step! * @size! / 100.0))
      tiling: env.tiling

    return createStepTool stepOpts, drawFunc
    */

  @draw = (...) ~>
    if not @func?
      @func = genFunc!
    @func(...)
  @endDraw = ~> ;

module.exports = RoundBrush
