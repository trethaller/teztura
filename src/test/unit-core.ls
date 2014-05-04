assert          = require 'assert'
{Vec2, Vec3}    = require '../core/vec'
Rect            = require '../core/rect'
{event}         = require '../core/utils'

assertClose = (a,b)->
  assert(Math.abs(a - b) < 1.0e-8, "#{a} != #{b}")

assertCloseRects = (r1, r2) ->
  assertClose r1.x, r2.x
  assertClose r1.y, r2.y
  assertClose r1.width, r2.width
  assertClose r1.height, r2.height

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
    assertCloseRects a, new Rect 5, 0, 15, 20
    a.extend(new Vec2(30,40))
    assertCloseRects a, new Rect 5, 0, 25, 40

  specify 'should not extend inner point', ->
    a = new Rect(10,10,10,10)
    a.extend(new Vec2(15,15))
    assert.deepEqual(a, new Rect(10,10,10,10))

  testWrap = (x, y, w, h, ww, wh) ->
    a = new Rect(x,y,w,h)
    return a.wrap ww, wh

  specify 'should not wrap inner rectangle', ->
    w = testWrap 10, 10, 10, 10, 30, 30
    assert w.length is 1
    assert.deepEqual w.0, new Rect(10,10,10,10)

    w2 = testWrap 40, 40, 10, 10, 30, 30
    assert w2.length is 1
    assert.deepEqual w2.0, new Rect(10,10,10,10)

  specify 'should wrap left/right', ->
    w = testWrap -5, 10, 10, 10, 30, 30
    assert w.length is 2
    assertCloseRects w[0], new Rect 0, 10, 5, 10
    assertCloseRects w[1], new Rect 25, 10, 5, 10

    w2 = testWrap 25, 10, 10, 10, 30, 30
    assertCloseRects w[0], w2[0]
    assertCloseRects w[1], w2[1]

  specify 'should wrap up/down', ->
    w = testWrap 10, -5, 10, 10, 30, 30
    assert w.length is 2
    assertCloseRects w[0], new Rect 10, 0, 10, 5
    assertCloseRects w[1], new Rect 10, 25, 10, 5

    w2 = testWrap 10, 25, 10, 10, 30, 30
    assertCloseRects w[0], w2[0]
    assertCloseRects w[1], w2[1]


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

describe 'Event', ->
  specify 'subscribe/unsubscribe', ->
    calls = []
    f1 = -> calls.push 'f1'
    f2 = -> calls.push 'f2'
    f3 = -> calls.push 'f3'
    history = (h) -> calls.join(',') is h

    evt = event!
      ..subscribe f1
      ..subscribe f2

    evt!
    assert history 'f1,f2'
    
    evt!
    assert history 'f1,f2,f1,f2'

    evt.unsubscribe f1
    evt!
    assert history 'f1,f2,f1,f2,f2'

    evt.unsubscribe f2
    evt!
    assert history 'f1,f2,f1,f2,f2'

  specify 'arguments', ->
    calls = []
    f1 = (a, b)-> calls.push "#{a}+#{b}"
    evt = event!
      ..subscribe f1

    evt '1', '2'
    assert calls.join(',') is '1+2'
    