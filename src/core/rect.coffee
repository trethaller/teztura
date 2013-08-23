
class Rect
  constructor: (@x, @y, @width, @height) -> ;
  intersect: (rect) ->
    nmaxx = Math.min(@x+@width, rect.x+rect.width)
    nmaxy = Math.min(@y+@height, rect.y+rect.height)
    nx = Math.max(@x, rect.x)
    ny = Math.max(@y, rect.y)
    return new Rect(nx, ny, Math.max(0, nmaxx-nx), Math.max(0, nmaxy-ny))
  union: (rect) ->
    ret = new Rect(@x,@y,@width,@height)
    ret.extend(rect.topLeft())
    ret.extend(rect.bottomRight())
    return ret

  clone: ->
    return new Rect(@x, @y, @width, @height)

  offset: (vec)->
    return new Rect(@x+vec.x, @y+vec.y, @width, @height)

  isEmpty: ()->
    return @width<=0 or @height<=0

  round: ()->
    return new Rect(
      Math.floor(@x),
      Math.floor(@y),
      Math.ceil(@width),
      Math.ceil(@height))

  extend: (obj) ->
    if obj.width?
      @extend(obj.topLeft())
      @extend(obj.bottomRight())
    else
      if obj.x < @x
        @width += @x - obj.x
        @x = obj.x
      else
        @width = Math.max(@width, obj.x - @x)
      if obj.y < @y
        @height += @y - obj.y
        @y = obj.y
      else
        @height = Math.max(@height, obj.y - @y)
    
  topLeft: ()->
    return new Vec2(@x,@y)
  bottomRight: ()->
    return new Vec2(@x+@width, @y+@height)

Rect.Empty = new Rect(0,0,0,0)
