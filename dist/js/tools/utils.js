(function(){
  var Rect, createStepTool, out$ = typeof exports != 'undefined' && exports || this;
  Rect = require('../core/rect');
  createStepTool = function(options, stepFunc){
    var step, tiling, lastpos, accumulator, draw, beginDraw, endDraw;
    step = options.step || 4.0;
    tiling = options.tiling || false;
    lastpos = null;
    accumulator = 0.0;
    draw = function(layer, pos, pressure){
      var wpos, rect, delt, length, dir, pt;
      wpos = tiling
        ? pos.wrap(layer.width, layer.height)
        : pos.clone();
      rect = new Rect(wpos.x, wpos.y, 1, 1);
      if (lastpos != null) {
        delt = pos.sub(lastpos);
        length = delt.length();
        dir = delt.scale(1.0 / length);
        while (accumulator + step <= length) {
          accumulator += step;
          pt = lastpos.add(dir.scale(accumulator));
          if (tiling) {
            pt = pt.wrap(layer.width, layer.height);
          }
          stepFunc(layer, pt, pressure, rect);
        }
        accumulator -= length;
      } else {
        stepFunc(layer, wpos, pressure, rect);
      }
      lastpos = pos.clone();
      return rect;
    };
    beginDraw = function(layer, pos){
      accumulator = 0;
    };
    endDraw = function(pos){
      lastpos = null;
    };
    return {
      draw: draw,
      beginDraw: beginDraw,
      endDraw: endDraw
    };
  };
  out$.createStepTool = createStepTool;
}).call(this);
