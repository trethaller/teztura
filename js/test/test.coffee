assert = require('assert')
Core = require('../core')

assertClose = (a,b)->
  assert(Math.abs(a-b) < 1.0e-8, "#{a} != #{b}")


V = (x,y)->
  return new Core.Vec2(x,y)

describe 'Rect', ()->
  it 'should intersect correctly', ()->
    a = new Core.Rect(10,20,100,100)
    b = new Core.Rect(20,10,100,100)
    assertClose(a.intersect(b).width, 90)
    assertClose(b.intersect(a).width, 90)
    assertClose(a.intersect(b).height, 90)
    assertClose(b.intersect(a).height, 90)
    a = new Core.Rect(0,0,100,100)
    b = new Core.Rect(200,50,100,100)
    assertClose(a.intersect(b).width, 0)
    assertClose(b.intersect(a).height, 50)
  
  it 'should intersect inner rect', ()->
    a = new Core.Rect(0,0,100,100)
    b = new Core.Rect(10,20,20,20)
    c = a.intersect(b)
    assert.deepEqual(b,c)

  it 'should union', ()->
    a = new Core.Rect(10,20,10,10)
    b = new Core.Rect(15,25,10,15)
    c = a.union(b)
    assertClose(c.x, 10)
    assertClose(c.y, 20)
    assertClose(c.width, 15)
    assertClose(c.height, 20)
   
  it 'should extend', ()->
    a = new Core.Rect(10,10,10,10)
    a.extend(V(5,0))
    assertClose(a.width, 15)
    assertClose(a.height, 20)
    assertClose(a.x, 5)
    assertClose(a.y, 0)
    a.extend(V(30,40))
    assertClose(a.width, 25)
    assertClose(a.height, 40)
    assertClose(a.x, 5)
    assertClose(a.y, 0)

  it 'should not extend inner point', ()->
    a = new Core.Rect(10,10,10,10)
    a.extend(V(15,15))
    assert.deepEqual(a, new Core.Rect(10,10,10,10))

describe 'Vec2', ()->
  it 'should add and sub', ()->
    va = new Core.Vec2(1,2)
    vb = new Core.Vec2(2,3)
    assertClose(va.add(vb).x, 3)
    assertClose(va.add(vb).y, 5)
    assertClose(va.sub(vb).x, -1)
    assertClose(va.sub(vb).y, -1)
  it 'should calculate length', ()->
    v = new Core.Vec2(3,4)
    assertClose(v.length(), 5)
  it 'should normalize', ()->
    v = new Core.Vec2(2,2)
    assertClose(v.normalized().length(), 1)
