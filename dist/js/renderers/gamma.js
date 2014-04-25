(function(){
  var createProperties, GammaRenderer;
  createProperties = require('../core/properties').createProperties;
  GammaRenderer = function(layer, view){
    var generateFunc, this$ = this;
    createProperties(this, [{
      id: 'gamma',
      name: "Gamma",
      defaultValue: 1.0,
      range: [0, 10]
    }]);
    generateFunc = function(){
      var width, height, imgData, fb, gamma, code;
      width = layer.width;
      height = layer.height;
      imgData = view.imageData.data;
      fb = layer.getBuffer();
      gamma = this$.gamma();
      code = "(function (rects) {'use strict';for(var ri in rects) {var r = rects[ri];var minX = r.x;var minY = r.y;var maxX = minX + r.width;var maxY = minY + r.height;for(var iy=minY; iy<=maxY; ++iy) {var offset = iy * width;for(var ix=minX; ix<=maxX; ++ix) {var fval = fb[offset + ix];fval = fval > 1.0 ? 1.0 : (fval < -1.0 ? -1.0 : fval);var val = Math.round(Math.pow((fval + 1.0) * 0.5, gamma) * 255.0) | 0;var off = (offset + ix) << 2;imgData[off] = val;imgData[off+1] = val;imgData[off+2] = val;imgData[off+3] = 0xff;}}view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);}});";
      return eval(code);
    };
    this.render = function(rects){
      if (this$.renderFunc == null) {
        this$.renderFunc = generateFunc();
      }
      this$.renderFunc(rects);
    };
  };
  module.exports = GammaRenderer;
}).call(this);
