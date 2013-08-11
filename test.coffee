
class Test extends Backbone.Model
  defaults: ->
    prop: 'hi'

  print: ->
  	console.log @get('prop')

t = new Test()
t.print()
t.set('prop', 'hey')
t.print()
