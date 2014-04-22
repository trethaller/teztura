module.exports = (function() {

  var properties = {
    gamma: 1.0
  };

  function renderLayer (layer, view, rects) {
    var width = layer.width;
    var height = layer.height;
    var imgData = view.imageData.data;
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
          var off = (offset + ix) << 2;
          imgData[off] = val;
          imgData[off+1] = val;
          imgData[off+2] = val;
          imgData[off+3] = 0xff;
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
