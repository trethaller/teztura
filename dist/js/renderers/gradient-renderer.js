
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
          var lookupIndex = Math.round(Math.min(511,Math.max(0,256.0 * (1.0 + fval)))) * 4;
          var off = (offset + ix) << 2;
          imgData[off] =  lut[lookupIndex];
          imgData[off+1] = lut[lookupIndex+1];
          imgData[off+2] = lut[lookupIndex+2];
          imgData[off+3] = 0xff;
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