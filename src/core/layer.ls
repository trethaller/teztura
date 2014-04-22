
class Layer
  (@width, @height) ->
    @buffer = new ArrayBuffer @width * @height * 4
    @fbuffer = new Float32Array @buffer

  getRect: ->
    new Rect 0,0,@width,@height

  getBuffer: ->
    @fbuffer

  getAt: (pos)->
    ipos = pos.wrap(@width, @height).round()
    @fbuffer[ ipos.y * @width + ipos.x ]

  getNormalAt: (pos, rad)->
    p = pos.round()
    fb = @fbuffer
    px = Math.round(pos.x)
    py = Math.round(pos.y)
    sx1 = fb[ py * @width + ((px-rad)%@width) ]
    sx2 = fb[ py * @width + ((px+rad)%@width) ]
    sy1 = fb[ ((py-rad) % @height) * @width + px ]
    sy2 = fb[ ((py+rad) % @height) * @width + px ]
    xvec = new Vec3(rad*2, 0, sx2 - sx1)
    yvec = new Vec3(0, rad*2, sy2 - sy1)
    norm = xvec.cross(yvec).normalized()

  getCopy: (rect)->
    srcData = @buffer
    dstData = new ArrayBuffer(rect.width * rect.height * 4)
    ``
    for(var iy=0; iy<rect.height; ++iy) {
      var src = new Uint32Array(srcData, 4 * ((iy + rect.y) * this.width + rect.x), rect.width);
      var dst = new Uint32Array(dstData, 4 * iy * rect.width, rect.width);
      dst.set(src);
    }``
    return dstData

  setData: (buffer, rect)!->
    dstData = @buffer
    ``
    for(var iy=0; iy<rect.height; ++iy) {
      var src = new Uint32Array(buffer, 4 * iy * rect.width, rect.width);
      var dstOff = 4 * ((iy + rect.y) * this.width + rect.x);
      var dst = new Uint32Array(dstData, dstOff, rect.width);
      dst.set(src);
    }``
  
  fill: (fn)->
    invw = 2.0 / (@width - 1)
    invh = 2.0 / (@height - 1)
    fb = @getBuffer()
    width = @width
    height = @height
    for iy from 0 til height
      i = iy * width
      for ix from 0 til width
        fb[i] = fn(ix * invw - 1.0, iy * invh - 1.0)
        ++i


module.exports = Layer