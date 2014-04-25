
Document = require './document'
DocumentView = require './document-view'
RoundBrush = require './tools/roundbrush'


PropertyView = (prop) !->
  @$el = $ '<div/>'
  $ '<span/>'
    .text prop.name
    .appendTo @$el

  @subs = []

  if prop.range?
    power = prop.power or 1.0
    conv = (v)-> Math.pow(v, power)
    invconv = (v)-> Math.pow(v, 1.0 / power)

    rmin = invconv prop.range[0]
    rmax = invconv prop.range[1]

    $input = $ '<input/>'
      .val prop.value!
      .appendTo @$el
      .change (evt)->
        if prop.type is 'int'
          prop.value parseInt $input.val!
        else
          prop.value parseFloat $input.val!

    $slider = $ '<input type="range"/>'
      .attr 'min', rmin
      .attr 'max', rmax
      .attr 'step', if prop.type is 'int' then 1 else (rmax - rmin) / 100
      .val invconv prop.value!
      .appendTo @$el
      .change (evt)->
        prop.value conv $slider.val!

    @subscription = prop.value.subscribe (newVal) ->
      $input.val newVal
      $slider.val invconv newVal

  @cleanup = ~>
    @subscription?.dispose!
    #ko.applyBindings prop, $range[0]
  

Editor = !->
  @tiling = -> true
  @tool = new RoundBrush this
  @toolObject = -> @tool

  @tool.properties.forEach (p)->
    pv = new PropertyView p
    $ \#properties
      .append pv.$el

start = ->
  editor = new Editor
  doc = new Document 512, 512
  doc.layer.fill -> -1
  view = new DocumentView $('.document-view'), doc, editor
  view.render!

$(document).ready start