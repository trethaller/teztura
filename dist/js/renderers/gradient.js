(function(){
  var createProperties, GradientRenderer;
  createProperties = require('../core/properties').createProperties;
  GradientRenderer = function(layer, view){
    var generateFunc, this$ = this;
    createProperties(this, [{
      id: 'gradient',
      name: "Gradient image",
      type: 'image'
    }]);
    function propChanged(pid, val, prev){
      return this$.renderFunc = null;
    }
    generateFunc = function(){
      var width, imgData, fb, lutImg, lut, round, norm, clamp, code;
      width = layer.width;
      imgData = view.imageData.data;
      fb = layer.getBuffer();
      lutImg = this$.gradient();
      if (lutImg == null) {
        return function(){};
      }
      lut = lutImg.data;
      round = function(val){
        return "(" + val + " + 0.5) | 0";
      };
      norm = function(val){
        return lutImg.width / 2 + ".0 * (1.0 + " + val + ")";
      };
      clamp = function(val){
        return val + " < 0 ? 0 : (" + val + " > " + (lutImg.width - 1) + " ? " + (lutImg.width - 1) + " : " + val + ")";
      };
      code = "(function (rects) {'use strict';for(var ri in rects) {var r = rects[ri];var minX = r.x | 0;var minY = r.y | 0;var maxX = minX + r.width | 0;var maxY = minY + r.height | 0;for(var iy=minY; iy<=maxY; ++iy) {var offset = iy * " + width + ";for(var ix=minX; ix<=maxX; ++ix) {var fval = " + round(norm('fb[offset + ix]')) + ";var lookupIndex = (" + clamp('fval') + ") << 2;var off = (offset + ix) << 2;imgData[off] =   lut[lookupIndex];imgData[++off] = lut[++lookupIndex];imgData[++off] = lut[++lookupIndex];imgData[++off] = 0xff;}}view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);}});";
      console.log(code);
      return eval(code);
    };
    this.render = function(rects){
      if (this$.renderFunc == null) {
        this$.renderFunc = generateFunc();
      }
      this$.renderFunc(rects);
    };
  };
  module.exports = GradientRenderer;
}).call(this);
