Core = require '../core/core'
Rect = require '../core/rect'
Layer = require '../core/layer'
{Vec2} = require '../core/vec'
GammaRenderer = require '../renderers/gamma-renderer'

$root = $ \#tests-root

testSection = (desc, fn)->
  $ \<h2>
    .text desc
    .appendTo $root
  $el = $ \<div> .appendTo $root
  $ \<hr>
    .appendTo $root
  fn $el

/*
testSection 'Round brush', ($el)->
  size = 200
  $can = $ "<canvas width='#{size * 4}' height='#{size}'/>"
    .appendTo $el
  layer = new Layer size, size
  layer.fill Core.getRoundBrushFunc 0  
*/

testSection 'Blend modes', ($el)->
  width = 800
  height = 400
  $can = $ "<canvas width='#{width}' height='#{height}'/>"
    .appendTo $el
  ctx = $can.0.getContext '2d'
  layer = new Layer width, height
  brush = new Layer 100, 100

  brush.fill Core.getRoundBrushFunc 0
  layer.fill (x,y)->
    x += 1
    y += 1
    (Math.round(x*80) % 2) * 0.1 - (Math.round(y*40) % 2) * 0.1

  blend-test = (y, args, expr)->
    fn = Core.genBlendFunc(args, expr)
    nsteps = 30
    for i from 0 til nsteps
      pressure = (1.0 - Math.cos(2 * Math.PI * i / nsteps)) * 0.5
      fn(new Vec2(i*width/nsteps - 50.0,y).round(), brush, layer, pressure)


  blend-test(0,   "intensity", "{dst} += {src} * intensity")
  blend-test(100, "intensity", "{dst} *= 1 + {src} * intensity")
  blend-test(200, "intensity", "{dst} = {dst} * (1 - intensity*{src}) + 0.5 * intensity*{src}")
  blend-test(300, "intensity", "{dst} = {src} * intensity")

  view = {
    canvas: $can.0
    context: ctx
    imageData: ctx.getImageData 0, 0, width, height
  }

  GammaRenderer.renderLayer layer, view, [new Rect(0,0,width,height)]
  ctx.drawImage $can.0, 0, 0



