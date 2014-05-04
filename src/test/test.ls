Core              = require '../core/core'
Rect              = require '../core/rect'
Layer             = require '../core/layer'
{Vec2}            = require '../core/vec'
{loadImageData}   = require '../core/utils'
GammaRenderer     = require '../renderers/gamma'
GradientRenderer  = require '../renderers/gradient'
RoundBrush        = require '../tools/roundbrush'
{ToolStack}       = require '../tools/stack'


mockEnv = (width, height)->
  {
    targetValue: 1.0
    tiling: true
    doc: {
      width, height
    }
  }

quickRender = (layer, canvas)->
  ctx = canvas.getContext '2d'
  view =
    canvas: canvas
    context: ctx
    imageData: ctx.getImageData 0, 0, layer.width, layer.height

  renderer = new GammaRenderer layer, view
  renderer.render [new Rect(0,0,layer.width,layer.height)]
  ctx.drawImage canvas, 0, 0

testStepTransform = ($el) ->
  width = 800
  height = 150
  $can = $ "<canvas width='#{width}' height='#{height}'/>"
    .appendTo $el
  layer = new Layer width, height
  layer.fill (x,y) -> -1

  env = mockEnv width, height
  brush = new RoundBrush env
  env.tool = brush
  stack = new ToolStack env

  stack.draw layer, new Vec2(100, 50), 1
  stack.draw layer, new Vec2(700, 50), 1
  stack.draw layer, new Vec2(700, 100), 1
  stack.draw layer, new Vec2(100, 100), 1
  stack.endDraw!

  quickRender layer, $can.0

testTiling = ($el)->
  width = 100
  height = 100
  $can = $ "<canvas width='#{width}' height='#{height}'/>"
    .appendTo $el
    .width 400
    .height 400

  layer = new Layer width, height
  layer.fill (x,y)-> -1

  b = new RoundBrush mockEnv width, height
    ..size 5
    ..hardness 0.0
    ..intensity 1.6

  point = (pos)!->
    b.draw layer, pos, 1
    b.endDraw!

  line = (start, step)!->
    for i from 0 to 30 by 1
      point start.add step.scale(i)

  line new Vec2(-30,    -45), new Vec2(2, 1)
  line new Vec2(-29.75, -40), new Vec2(2, 1)
  line new Vec2(-29.5,  -35), new Vec2(2, 1)
  line new Vec2(-29.25, -30), new Vec2(2, 1)

  b.size 12
  b.hardness 0.6

  point new Vec2(-3, -3)
  point new Vec2(3, -3)
  point new Vec2(3, 3)
  point new Vec2(-3, 3)

  b.size 6
  b.hardness 0
  line new Vec2(-30, 15), new Vec2(2, 0)
  line new Vec2(-40, 20), new Vec2(2.67, 0)

  b.size 4
  line new Vec2(-20, 25), new Vec2(1.3, 0)

  ctx = $can.0.getContext '2d'
  view =
    canvas: $can.0
    context: ctx
    imageData: ctx.getImageData 0, 0, width, height

  renderer = new GammaRenderer layer, view
  renderer.render [new Rect(0,0,width,height)]

  ctx.translate width / 2, height / 2
  ctx.fillStyle = ctx.createPattern $can.0, "repeat"
  ctx.fillRect(-width / 2,-height / 2, width, height)

testRenderers = ($el)->
  width = 800
  height = 100

  render-test = (type, props)->
    $can = $ "<canvas width='#{width}' height='#{height}'/>"
      .appendTo $el
    layer = new Layer width, height
    layer.fill (x,y) ->
      if y > 0
      then ((Math.floor((x+1)*40) % 2) - (Math.floor(y*5) % 2)) * (x+1) / 2.0
      else x
    
    ctx = $can.0.getContext '2d'
    view =
      canvas: $can.0
      context: ctx
      imageData: ctx.getImageData 0, 0, width, height
    renderer = new type layer, view
    for k, v of props
      renderer[k](v)
    renderer.render [new Rect(0,0,width,height)]
    ctx.drawImage $can.0, 0, 0

  render-test GammaRenderer, {gamma: 0.1}
  render-test GammaRenderer, {gamma: 1.0}
  render-test GammaRenderer, {gamma: 2.0}

  g1 <- loadImageData '/img/gradient-1.png'
  render-test GradientRenderer, {gradient: g1}

testRoundBrush = ($el)->
  width = 800
  height = 400
  $can = $ "<canvas width='#{width}' height='#{height}'/>"
    .appendTo $el
  layer = new Layer width, height
  layer.fill (x,y)-> -1

  brush-test = (ypos, props) !->
    f = (xoffset, tiling) !->

      env = mockEnv width, height
      env.doc.tiling = tiling

      brush = new RoundBrush env
      for k, v of props
        brush[k](v)

      steps = 30
      for i from 0 to steps
        t = i / steps
        pos = new Vec2(xoffset + t * 300, ypos - 30 * Math.sin(Math.PI * t))
        brush.draw layer, pos, 1
      brush.endDraw!

    f 50, false
    f 450, true

  y = 0
  brush-test (y+=50), {}
  brush-test (y+=50), {size: 50}
  brush-test (y+=50), {size: 50, step: 30}
  brush-test (y+=50), {size: 50, step: 50}
  brush-test (y+=50), {size: 50, step: 30, hardness: 0.3}
  brush-test (y+=50), {size: 50, step: 30, hardness: 0.5}
  brush-test (y+=50), {size: 50, step: 30, hardness: 1.0}

  quickRender layer, $can.0

testBlendModes = ($el)->
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

  quickRender layer, $can.0

# ----

tests = [
  ["Step transform", testStepTransform]
  ["Tiling", testTiling]
  ["Renderers", testRenderers]
  ["Blend modes", testBlendModes]
  ["Round brush", testRoundBrush]
]

do ->
  $root = $ \#tests-root
  tests.forEach (t)->
    $ \<h2>
      .text t.0
      .appendTo $root
    $el = $ \<div> .appendTo $root
    $ \<hr>
      .appendTo $root
    t[1]($el)
