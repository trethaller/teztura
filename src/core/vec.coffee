
class Vec2
  constructor: (@x, @y) ->;
  clone: ()->
    return new Vec2(@x,@y)
  distanceTo: (v) ->
    return Math.sqrt(squareDistanceTo(v))
  squareDistanceTo: (v) ->
    dx = @x - v.x
    dy = @y - v.y
    return dx*dx + dy*dy
  round: ()->
    return new Vec2(Math.round(@x), Math.round(@y))
  add: (v) ->
    return new Vec2(@x+v.x, @y+v.y)
  sub: (v) ->
    return new Vec2(@x-v.x, @y-v.y)
  scale: (s) ->
    return new Vec2(@x*s, @y*s)
  length: () ->
    return Math.sqrt(@squareLength())
  squareLength: () ->
    return @x*@x+@y*@y
  normalized: () ->
    return @scale(1.0 / @length())
  wrap: (w,h)->
    return new Vec2(
      (@x % w + w) % w,
      (@y % h + h) % h)

class Vec3
  constructor: (@x, @y, @z) ->;
  add: (v) ->
    return new Vec3(@x+v.x, @y+v.y, @z+v.z)
  sub: (v) ->
    return new Vec3(@x-v.x, @y-v.y, @z-v.z)
  scale: (s) ->
    return new Vec3(@x*s, @y*s, @z*s)
  length: () ->
    return Math.sqrt(@squareLength())
  squareLength: () ->
    return @x*@x+@y*@y+@z*@z
  normalized: () ->
    return @scale(1.0 / @length())
  cross: (v)->
    return new Vec3(
      (@y * v.z - @z * v.y),
      (@z * v.x - @x * v.z),
      (@x * v.y - @y * v.x))
  dot: (v)->
    return @x+v.x + @y+v.y + @z+v.z

