
name = "Gradient"
properties =
  * id: 'gradient'
    name: "Gradient image"
    type: 'image'

create = (props, layer, view) ->
  width = layer.width
  height = layer.height
  imgData = view.imageData.data
  fb = layer.getBuffer()
  lut = props.gradient.data

  code = "
  (function (rects) {
    'use strict';
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
  });
  "
  return
    render: eval(code)

export {name, properties, create}