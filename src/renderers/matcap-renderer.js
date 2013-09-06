
MatcapRenderer = (function(){
  var properties = {
    gain: 3.0,
    matcap: null
  };

  function renderLayer (layer, view, rects) {
    var width = layer.width;
    var height = layer.height;
    var imgData = view.imageData.data;
    var fb = layer.getBuffer();
    var dz = 1.0 / (properties.gain);
    var matcapData = properties.matcap.data;
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
          var fac = 256.0 / Math.sqrt(dx*dx + dy*dy + dz*dz);
          var lookupX = Math.round(dx * fac + 255.0);
          var lookupY = Math.round(-dy * fac + 255.0);
          var lookup = (lookupY * 512 + lookupX) * 4;
          var i = (iy * width + ix) << 2;
          imgData[i]   = matcapData[lookup];
          imgData[i+1] = matcapData[lookup+1];
          imgData[i+2] = matcapData[lookup+2];
          imgData[i+3] = 0xff;
        }
      }
      view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);
    }
  }

  return {
    description: {
      name: "Matcap"
    },
    properties: properties,
    renderLayer: renderLayer
  };
})();
