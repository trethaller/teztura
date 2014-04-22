{Vec2} = require './vec'

class Rect
  (@x, @y, @width, @height)->;

  intersect: (rect)->
    nmaxx = Math.min(@x + @width, rect.x + rect.width)
    nmaxy = Math.min(@y + @height, rect.y + rect.height)
    nx = Math.max(@x, rect.x)
    ny = Math.max(@y, rect.y)
    new Rect(nx, ny, Math.max(0, nmaxx - nx), Math.max(0, nmaxy - ny))

  union: (rect)->
    new Rect(@x,@y,@width,@height)
      ..extend(rect.topLeft())
      ..extend(rect.bottomRight())

  clone: ->
    new Rect(@x, @y, @width, @height)

  offset: (vec)->
    new Rect(@x + vec.x, @y + vec.y, @width, @height)

  isEmpty: ->
    @width <= 0 or @height <= 0

  round: ->
    new Rect(
      Math.floor(@x),
      Math.floor(@y),
      Math.ceil(@width),
      Math.ceil(@height))

  extend: (obj)->
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
    
  topLeft: ->
    new Vec2(@x,@y)

  bottomRight: ->
    new Vec2(@x + @width, @y + @height)

Rect.Empty = new Rect(0,0,0,0)

module.exports = Rect