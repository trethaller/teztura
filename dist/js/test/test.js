(function(){
  var Core, Rect, Layer, Vec2, GammaRenderer, $root, testSection;
  Core = require('../core/core');
  Rect = require('../core/rect');
  Layer = require('../core/layer');
  Vec2 = require('../core/vec').Vec2;
  GammaRenderer = require('../renderers/gamma-renderer');
  $root = $('#tests-root');
  testSection = function(desc, fn){
    var $el;
    $('<h2>').text(desc).appendTo($root);
    $el = $('<div>').appendTo($root);
    $('<hr>').appendTo($root);
    return fn($el);
  };
  testSection('Blend modes', function($el){
    var width, height, $can, ctx, layer, brush, blendTest, view;
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
    GammaRenderer.renderLayer(layer, view, [new Rect(0, 0, width, height)]);
    return ctx.drawImage($can[0], 0, 0);
  });
}).call(this);
