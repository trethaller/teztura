(function(){
  var createStepTool, out$ = typeof exports != 'undefined' && exports || this;
  createStepTool = function(properties, stepFunc){
    var lastpos, accumulator, draw, endDraw;
    lastpos = null;
    accumulator = 0.0;
    draw = function(layer, pos, pressure){
      var tiling, step, wpos, rect, delt, length, dir, pt;
      tiling = properties.tiling;
      step = properties.step;
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
    endDraw = function(pos){
      accumulator = 0;
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
