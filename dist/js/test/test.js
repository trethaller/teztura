(function(){
  var Core, Rect, Layer, Vec2, loadImageData, GammaRenderer, GradientRenderer, RoundBrush, testRenderers, testRoundBrush, testBlendModes, tests;
  Core = require('../core/core');
  Rect = require('../core/rect');
  Layer = require('../core/layer');
  Vec2 = require('../core/vec').Vec2;
  loadImageData = require('../core/utils').loadImageData;
  GammaRenderer = require('../renderers/gamma');
  GradientRenderer = require('../renderers/gradient');
  RoundBrush = require('../tools/roundbrush');
  testRenderers = function($el){
    var width, height, renderTest;
    width = 800;
    height = 100;
    renderTest = function(type, props){
      var $can, layer, ctx, view, renderer, k, v;
      $can = $("<canvas width='" + width + "' height='" + height + "'/>").appendTo($el);
      layer = new Layer(width, height);
      layer.fill(function(x, y){
        if (y > 0) {
          return (Math.floor((x + 1) * 40) % 2 - Math.floor(y * 5) % 2) * (x + 1) / 2.0;
        } else {
          return x;
        }
      });
      ctx = $can[0].getContext('2d');
      view = {
        canvas: $can[0],
        context: ctx,
        imageData: ctx.getImageData(0, 0, width, height)
      };
      renderer = new type(layer, view);
      for (k in props) {
        v = props[k];
        renderer[k](v);
      }
      renderer.render([new Rect(0, 0, width, height)]);
      return ctx.drawImage($can[0], 0, 0);
    };
    renderTest(GammaRenderer, {
      gamma: 0.1
    });
    renderTest(GammaRenderer, {
      gamma: 1.0
    });
    renderTest(GammaRenderer, {
      gamma: 2.0
    });
    return loadImageData('/img/gradient-1.png', function(g1){
      return renderTest(GradientRenderer, {
        gradient: g1
      });
    });
  };
  testRoundBrush = function($el){
    var width, height, $can, layer, brushTest, y, ctx, view, renderer;
    width = 800;
    height = 400;
    $can = $("<canvas width='" + width + "' height='" + height + "'/>").appendTo($el);
    layer = new Layer(width, height);
    layer.fill(function(x, y){
      return -1;
    });
    brushTest = function(ypos, props){
      var f;
      f = function(xoffset, tiling){
        var env, brush, k, ref$, v, steps, i$, i, t, pos;
        env = {
          tiling: tiling,
          targetValue: 1.0
        };
        brush = new RoundBrush(env);
        for (k in ref$ = props) {
          v = ref$[k];
          brush[k](v);
        }
        brush.beginDraw(layer, new Vec2(0, ypos));
        steps = 20;
        for (i$ = 0; i$ <= steps; ++i$) {
          i = i$;
          t = i / steps;
          pos = new Vec2(xoffset + t * 300, ypos - 30 * Math.sin(Math.PI * t));
          brush.draw(layer, pos, 1);
        }
        brush.endDraw();
      };
      f(50, false);
      f(450, true);
    };
    y = 0;
    brushTest(y += 50, {});
    brushTest(y += 50, {
      size: 50
    });
    brushTest(y += 50, {
      size: 50,
      step: 30
    });
    brushTest(y += 50, {
      size: 50,
      step: 50
    });
    brushTest(y += 50, {
      size: 50,
      step: 30,
      hardness: 0.3
    });
    brushTest(y += 50, {
      size: 50,
      step: 30,
      hardness: 0.5
    });
    brushTest(y += 50, {
      size: 50,
      step: 30,
      hardness: 1.0
    });
    ctx = $can[0].getContext('2d');
    view = {
      canvas: $can[0],
      context: ctx,
      imageData: ctx.getImageData(0, 0, width, height)
    };
    renderer = new GammaRenderer(layer, view);
    renderer.render([new Rect(0, 0, width, height)]);
    return ctx.drawImage($can[0], 0, 0);
  };
  testBlendModes = function($el){
    var width, height, $can, ctx, layer, brush, blendTest, view, renderer;
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
    renderer = new GammaRenderer(layer, view);
    renderer.render([new Rect(0, 0, width, height)]);
    return ctx.drawImage($can[0], 0, 0);
  };
  tests = [["Renderers", testRenderers], ["Blend modes", testBlendModes], ["Round brush", testRoundBrush]];
  (function(){
    var $root;
    $root = $('#tests-root');
    return tests.forEach(function(t){
      var $el;
      $('<h2>').text(t[0]).appendTo($root);
      $el = $('<div>').appendTo($root);
      $('<hr>').appendTo($root);
      return t[1]($el);
    });
  })();
}).call(this);
