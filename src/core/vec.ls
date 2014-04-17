
class Vec2
  (@x, @y) ->;

  clone: ->
    new Vec2(@x,@y)
  distanceTo: (v) ->
    Math.sqrt(squareDistanceTo(v))
  squareDistanceTo: (v) ->
    dx = @x - v.x
    dy = @y - v.y
    dx*dx + dy*dy
  round: ->
    new Vec2(Math.round(@x), Math.round(@y))
  add: (v) ->
    new Vec2(@x + v.x, @y + v.y)
  sub: (v) ->
    new Vec2(@x - v.x, @y - v.y)
  scale: (s) ->
    new Vec2(@x*s, @y*s)
  length: ->
    Math.sqrt(@squareLength())
  squareLength: ->
    @x*@x + @y*@y
  normalized: ->
    @scale(1.0 / @length())
  wrap: (w,h)->
    new Vec2(
      (@x % w + w) % w,
      (@y % h + h) % h)
  toString: ->
    @x + ", " + @y

class Vec3
  (@x, @y, @z) ->;

  add: (v) ->
    new Vec3(@x + v.x, @y + v.y, @z + v.z)
  sub: (v) ->
    new Vec3(@x - v.x, @y - v.y, @z - v.z)
  scale: (s) ->
    new Vec3(@x*s, @y*s, @z*s)
  length: ->
    Math.sqrt(@squareLength())
  squareLength: ->
    @x*@x + @y*@y + @z*@z
  normalized: ->
    @scale(1.0 / @length())
  cross: (v)->
    new Vec3(
      (@y * v.z - @z * v.y),
      (@z * v.x - @x * v.z),
      (@x * v.y - @y * v.x))
  dot: (v)->
    @x + v.x + @y + v.y + @z + v.z

  toString: ->
    @x + ", " + @y + ", " + @z

export { Vec2, Vec3 }