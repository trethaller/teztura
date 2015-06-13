{ createProperties } = require '../core/properties'


NormalRenderer = (layer, view) !->
  createProperties @, [
    * id: 'gain'
      name: "Gain"
      defaultValue: 1.0
      range: [0, 10]
  ]

  @name = "Normal"

  @propertyChanged.subscribe ~>
    @renderFunc = null

  generateFunc = ~>
    ``
    function renderLayer (layer, view, rects) {   
      var width = layer.width;
      var height = layer.height;
      var imgData = view.imageData.data;
      var fb = layer.getBuffer();
      var dz = 1.0 / (this$.gain());
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
    };
    ``
    fimpl = renderLayer
    return (rects) ->
      fimpl layer, view, rects

  @render = (rects) !~>
    if not @renderFunc?
      @renderFunc = generateFunc!
    @renderFunc rects

module.exports = NormalRenderer