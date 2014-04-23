Core = require '../core/core'
Rect = require '../core/rect'
Layer = require '../core/layer'
{Vec2} = require '../core/vec'
GammaRenderer = require '../renderers/gamma'
RoundBrush = require '../tools/roundbrush'

$root = $ \#tests-root

testSection = (desc, fn)->
  $ \<h2>
    .text desc
    .appendTo $root
  $el = $ \<div> .appendTo $root
  $ \<hr>
    .appendTo $root
  fn $el


testSection 'Round brush', ($el)->
  width = 800
  height = 400
  $can = $ "<canvas width='#{width}' height='#{height}'/>"
    .appendTo $el
  layer = new Layer width, height
  layer.fill (x,y)-> -1

  defaults = -> {[p.id, p.defaultValue] for p in RoundBrush.properties}
  brush-test = (ypos, props) !->
    f = (xoffset, tiling) !->
      env =
        tiling: tiling
        targetValue: 1.0

      brush = RoundBrush.createTool props, env
      brush.beginDraw layer, new Vec2(0, ypos)
      steps = 20
      for i from 0 to steps
        t = i / steps
        pos = new Vec2(xoffset + t * 300, ypos - 30 * Math.sin(Math.PI * t))
        brush.draw layer, pos, 1
      brush.endDraw!

    f 50, false
    f 450, true

  p = defaults!
    ..hardness = 0
  y = 0
  brush-test (y+=50), p
  p.size = 50
  brush-test (y+=50), p
  p.step = 30
  brush-test (y+=50), p
  p.step = 50
  brush-test (y+=50), p
  p.step = 30
  p.hardness = 0.3
  brush-test (y+=50), p
  p.hardness = 0.5
  brush-test (y+=50), p
  p.hardness = 1.0
  brush-test (y+=50), p

  ctx = $can.0.getContext '2d'
  view =
    canvas: $can.0
    context: ctx
    imageData: ctx.getImageData 0, 0, width, height

  renderer = GammaRenderer.create {gamma: 1}, layer, view
  renderer.render [new Rect(0,0,width,height)]
  ctx.drawImage $can.0, 0, 0



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

  renderer = GammaRenderer.create {gamma: 1}, layer, view
  renderer.render [new Rect(0,0,width,height)]
  ctx.drawImage $can.0, 0, 0

