{ createProperties } = require '../core/properties'

Gradients = [
  * src: 'img/gradient-1.png'
  * src: 'img/gradient-2.png'
]

GradientRenderer = (layer, view) !->
  createProperties @, [
    * id: 'gradient'
      name: "Gradient image"
      type: 'gradient'
      choices: Gradients
      defaultValue: Gradients.0
  ]

  @name = "Gradient"

  @propertyChanged.subscribe ~>
    @renderFunc = null

  generateFunc = ~>
    width = layer.width
    lutImg = @gradient!?.data

    if not lutImg?.width?
      return ->;

    round = (val)-> "(#{val} + 0.5) | 0"
    norm = (val)-> "#{lutImg.width / 2}.0 * (1.0 + #{val})"
    clamp = (val)-> "#{val} < 0 ? 0 : (#{val} > #{lutImg.width-1} ? #{lutImg.width-1} : #{val})"

    code = "
    (function (rects, view, lut, fb) {
      'use strict';
      var imgData = view.imageData.data;
      for(var ri in rects) {
        var r = rects[ri];
        var minX = r.x | 0;
        var minY = r.y | 0;
        var maxX = minX + r.width | 0;
        var maxY = minY + r.height | 0;
        for(var iy=minY; iy<=maxY; ++iy) {
          var offset = iy * #{width};
          for(var ix=minX; ix<=maxX; ++ix) {
            var fval = #{round(norm('fb[offset + ix]'))};
            var lookupIndex = (#{clamp('fval')}) << 2;
            var off = (offset + ix) << 2;
            imgData[off] =   lut[lookupIndex];
            imgData[++off] = lut[++lookupIndex];
            imgData[++off] = lut[++lookupIndex];
            imgData[++off] = 0xff;
          }
        }
        view.context.putImageData(view.imageData, 0, 0, r.x, r.y, r.width+1, r.height+1);
      }
    });
    "
    fimpl = eval code
    return (rects) ->
      fb = layer.getBuffer!
      lut = lutImg.data
      fimpl rects, view, lut, fb

  @render = (rects) !~>
    if not @renderFunc?
      @renderFunc = generateFunc!
    @renderFunc rects

module.exports = GradientRenderer