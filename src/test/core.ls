assert          = require 'assert'
{Vec2, Vec3}    = require '../core/vec'
{Rect}          = require '../core/rect'

assertClose = (a,b)->
  assert(Math.abs(a - b) < 1.0e-8, "#{a} != #{b}")


describe 'Rect', ->
  specify 'should intersect correctly', ->
    a = new Rect(10,20,100,100)
    b = new Rect(20,10,100,100)
    assertClose(a.intersect(b).width, 90)
    assertClose(b.intersect(a).width, 90)
    assertClose(a.intersect(b).height, 90)
    assertClose(b.intersect(a).height, 90)
    a = new Rect(0,0,100,100)
    b = new Rect(200,50,100,100)
    assertClose(a.intersect(b).width, 0)
    assertClose(b.intersect(a).height, 50)
  
  specify 'should intersect inner rect', ->
    a = new Rect(0,0,100,100)
    b = new Rect(10,20,20,20)
    c = a.intersect(b)
    assert.deepEqual(b,c)

  specify 'should union', ->
    a = new Rect(10,20,10,10)
    b = new Rect(15,25,10,15)
    c = a.union(b)
    assertClose(c.x, 10)
    assertClose(c.y, 20)
    assertClose(c.width, 15)
    assertClose(c.height, 20)
   
  specify 'should extend', ->
    a = new Rect(10,10,10,10)
    a.extend(new Vec2(5,0))
    assertClose(a.width, 15)
    assertClose(a.height, 20)
    assertClose(a.x, 5)
    assertClose(a.y, 0)
    a.extend(new Vec2(30,40))
    assertClose(a.width, 25)
    assertClose(a.height, 40)
    assertClose(a.x, 5)
    assertClose(a.y, 0)

  specify 'should not extend inner point', ->
    a = new Rect(10,10,10,10)
    a.extend(new Vec2(15,15))
    assert.deepEqual(a, new Rect(10,10,10,10))


describe 'Vec2', ->
  specify 'should add and sub', ->
    va = new Vec2(1,2)
    vb = new Vec2(2,3)
    assertClose(va.add(vb).x, 3)
    assertClose(va.add(vb).y, 5)
    assertClose(va.sub(vb).x, -1)
    assertClose(va.sub(vb).y, -1)

  specify 'should calculate length', ->
    v = new Vec2(3,4)
    assertClose(v.length(), 5)

  specify 'should normalize', ->
    v = new Vec2(2,2)
    assertClose(v.normalized().length(), 1)


describe 'Vec3', ->
  specify 'should add and sub', ->
    va = new Vec3(1,2,3)
    vb = new Vec3(2,3,4)
    assertClose(va.add(vb).x, 3)
    assertClose(va.add(vb).y, 5)
    assertClose(va.add(vb).z, 7)
    assertClose(va.sub(vb).x, -1)
    assertClose(va.sub(vb).y, -1)
    assertClose(va.sub(vb).z, -1)
