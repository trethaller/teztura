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
