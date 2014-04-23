(function(){
  var Core, Rect, Layer, Vec2, GammaRenderer, RoundBrush, testRenderers, testRoundBrush, testBlendModes, tests;
  Core = require('../core/core');
  Rect = require('../core/rect');
  Layer = require('../core/layer');
  Vec2 = require('../core/vec').Vec2;
  GammaRenderer = require('../renderers/gamma');
  RoundBrush = require('../tools/roundbrush');
  testRenderers = function($el){
    var width, height, x$, props, p, brush, renderTest;
    width = 800;
    height = 150;
    x$ = props = (function(){
      var i$, ref$, len$, results$ = {};
      for (i$ = 0, len$ = (ref$ = RoundBrush.properties).length; i$ < len$; ++i$) {
        p = ref$[i$];
        results$[p.id] = p.defaultValue;
      }
      return results$;
    }());
    x$.hardness = 0.8;
    x$.step = 60;
    x$.size = 100;
    brush = RoundBrush.createTool(props, {
      tiling: false,
      targetValue: 1.0
    });
    renderTest = function(type, props){
      var $can, layer, ctx, view, renderer;
      $can = $("<canvas width='" + width + "' height='" + height + "'/>").appendTo($el);
      layer = new Layer(width, height);
      layer.fill(function(x, y){
        return -1;
      });
      brush.beginDraw(layer, new Vec2(0, 150));
      brush.draw(layer, new Vec2(75, 75), 1);
      brush.draw(layer, new Vec2(750, 75), 1);
      brush.endDraw();
      ctx = $can[0].getContext('2d');
      view = {
        canvas: $can[0],
        context: ctx,
        imageData: ctx.getImageData(0, 0, width, height)
      };
      renderer = type.create(props, layer, view);
      renderer.render([new Rect(0, 0, width, height)]);
      return ctx.drawImage($can[0], 0, 0);
    };
    renderTest(GammaRenderer, {
      gamma: 0.1
    });
    renderTest(GammaRenderer, {
      gamma: 0.5
    });
    renderTest(GammaRenderer, {
      gamma: 1.0
    });
    return renderTest(GammaRenderer, {
      gamma: 2.0
    });
  };
  testRoundBrush = function($el){
    var width, height, $can, layer, defaults, brushTest, x$, p, y, ctx, view, renderer;
    width = 800;
    height = 400;
    $can = $("<canvas width='" + width + "' height='" + height + "'/>").appendTo($el);
    layer = new Layer(width, height);
    layer.fill(function(x, y){
      return -1;
    });
    defaults = function(){
      var i$, ref$, len$, p, results$ = {};
      for (i$ = 0, len$ = (ref$ = RoundBrush.properties).length; i$ < len$; ++i$) {
        p = ref$[i$];
        results$[p.id] = p.defaultValue;
      }
      return results$;
    };
    brushTest = function(ypos, props){
      var f;
      f = function(xoffset, tiling){
        var env, brush, steps, i$, i, t, pos;
        env = {
          tiling: tiling,
          targetValue: 1.0
        };
        brush = RoundBrush.createTool(props, env);
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
    x$ = p = defaults();
    x$.hardness = 0;
    y = 0;
    brushTest(y += 50, p);
    p.size = 50;
    brushTest(y += 50, p);
    p.step = 30;
    brushTest(y += 50, p);
    p.step = 50;
    brushTest(y += 50, p);
    p.step = 30;
    p.hardness = 0.3;
    brushTest(y += 50, p);
    p.hardness = 0.5;
    brushTest(y += 50, p);
    p.hardness = 1.0;
    brushTest(y += 50, p);
    ctx = $can[0].getContext('2d');
    view = {
      canvas: $can[0],
      context: ctx,
      imageData: ctx.getImageData(0, 0, width, height)
    };
    renderer = GammaRenderer.create({
      gamma: 1
    }, layer, view);
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
    renderer = GammaRenderer.create({
      gamma: 1
    }, layer, view);
    renderer.render([new Rect(0, 0, width, height)]);
    return ctx.drawImage($can[0], 0, 0);
  };
  tests = [["Renderers", testRenderers]];
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
