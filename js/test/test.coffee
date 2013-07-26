assert = require('assert')
Core = require('../core')


describe 'Rect', ()->
  it 'should intersect correctly', ()->
    a = new Core.Rect(10,20,100,100)
    b = new Core.Rect(20,10,100,100)
    assert.equal(a.intersect(b).width, 90)
    assert.equal(b.intersect(a).width, 90)
    assert.equal(a.intersect(b).height, 90)
    assert.equal(b.intersect(a).height, 90)
    a = new Core.Rect(0,0,100,100)
    b = new Core.Rect(200,50,100,100)
    assert.equal(a.intersect(b).width, 0)
    assert.equal(b.intersect(a).height, 50)

describe 'Vector', ()->
  it 'should add and sub', ()->
    va = new Core.Vector(1,2)
    vb = new Core.Vector(2,3)
    assert.equal(va.add(vb).x, 3)
    assert.equal(va.add(vb).y, 5)
    assert.equal(va.sub(vb).x, -1)
    assert.equal(va.sub(vb).y, -1)
  it 'should calculate length', ()->
    v = new Core.Vector(3,4)
    assert.equal(v.length(), 5)
  it 'should normalize', ()->
    v = new Core.Vector(2,2)
    assert.equal(v.normalized().length(), 1)
