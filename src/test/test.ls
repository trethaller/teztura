Core = require '../core/core'
Layer = require '../core/layer'
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


testSection 'Blend modes', ($el)->
  width = 400
  height = 100
  $can = $ \#canvas
    .width width
    .height height
    .appendTo $el
  ctx = $can.0.getContext '2d'
  layer = new Layer width, height
  brush = new Layer height, height

  brush.fill Core.getRoundBrushFunc 0
  layer.fill (x,y)->
    x += 1
    y += 1
    (Math.round(x*40) % 2) * 0.1 - (Math.round(y*40) % 2) * 0.1

  view = {
    canvas: $can.0
    context: ctx
    imageData: ctx.getImageData 0, 0, width, height
  }

  GammaRenderer.renderLayer layer, view, [new Rect(0,0,width,height)]
  ctx.drawImage canvas, 0, 0



