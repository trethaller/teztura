GammaRenderer = (function() {
  
  var properties = {
    gamma: 1.0
  };

  function renderLayer (layer, view, rects) {
    var width = layer.width;
    var height = layer.height;
    var destBuffer = new Uint32Array(view.imageData.data.buffer);
    var fb = layer.getBuffer();
    var gamma = properties.gamma;
    for(var ri in rects) {
      var r = rects[ri];
      var minX = r.x;
      var minY = r.y;
      var maxX = minX + r.width;
      var maxY = minY + r.height;
      for(var iy=minY; iy<=maxY; ++iy) {
        var offset = iy * width;
        for(var ix=minX; ix<=maxX; ++ix) {
          var fval = fb[offset + ix];
          fval = fval > 1.0 ? 1.0 : (fval < -1.0 ? -1.0 : fval);
          var val = Math.round(Math.pow((fval + 1.0) * 0.5, gamma) * 255.0);
          destBuffer[offset + ix] =
            (val) | (val << 8) | (val << 16) | 0xff000000;
        }
      }
      view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);
    }
  }

  return {
    description: {
      name: "Height map"
    },
    properties: properties,
    renderLayer: renderLayer
  };
})();

GradientRenderer = (function() {
  properties = {
    gradient: null
  };

  function renderLayer (layer, view, rects) {
    if(!properties.gradient)
      return;
    var width = layer.width;
    var height = layer.height;
    var imgData = view.imageData.data;
    var destBuffer = new Uint32Array(view.imageData.data.buffer);
    var fb = layer.getBuffer();
    var gamma = properties.gamma;
    var lut = properties.gradient.lut;
    for(var ri in rects) {
      var r = rects[ri];
      var minX = r.x;
      var minY = r.y;
      var maxX = minX + r.width;
      var maxY = minY + r.height;
      for(var iy=minY; iy<=maxY; ++iy) {
        var offset = iy * width;
        for(var ix=minX; ix<=maxX; ++ix) {
          var fval = fb[offset + ix];
          var lookup = lut[
            Math.round(
              Math.min(511,
                Math.max(0,
                  256.0 * (1.0 + fval)
                )
              )
            )
          ];
          destBuffer[offset + ix] = lookup;
        }
      }
      view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);
    }
  }

  return {
    description: {
      name: "Gradient"
    },
    properties: properties,
    renderLayer: renderLayer
  };
})();

NormalRenderer = (function(){
  var properties = {
    gain: 4.0
  };

  function renderLayer (layer, view, rects) {
    var width = layer.width;
    var height = layer.height;
    var imgData = view.imageData.data;
    var fb = layer.getBuffer();
    var dz = 1.0 / (properties.gain);
    for(var ri in rects) {
      var r = rects[ri];
      var minX = r.x;
      var minY = r.y;
      var maxX = minX + r.width;
      var maxY = minY + r.height;
      for(var iy=minY; iy<=maxY; ++iy) {
        for(var ix=minX; ix<=maxX; ++ix) {
          var sx1 = fb[ ((iy + height) % height) * width + ((ix - 1 + width) % width) ];
          var sx2 = fb[ ((iy + height) % height) * width + ((ix + 1 + width) % width) ];
          var sy1 = fb[ ((iy - 1 + height) % height) * width + ((ix + width) % width) ];
          var sy2 = fb[ ((iy + 1 + height) % height) * width + ((ix + width) % width) ];
          var dx = sx2 - sx1;
          var dy = sy2 - sy1;
          var fac = 128.0 / Math.sqrt(dx*dx + dy*dy + dz*dz);
          var i = (iy * width + ix) << 2;
          imgData[i]   = dx * fac + 127.0;
          imgData[++i] = dy * fac + 127.0;
          imgData[++i] = dz * fac + 127.0;
          imgData[++i] = 0xff;
        }
      }
      view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);
    }
  }

  return {
    description: {
      name: "Normal map"
    },
    properties: properties,
    renderLayer: renderLayer
  };
})();
