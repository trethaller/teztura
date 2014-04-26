
{ Vec2 } = require './core/vec'
Document = require './document'
DocumentView = require './document-view'
RoundBrush = require './tools/roundbrush'

makeDraggable = (el)->
  function DragHelper @el
    @startPos = null
    @lastPos = null
    @delta = null

    @cleanup = ->
      stopDrag!
      @el.off 'mousedown', startDrag

    evtPos = (e) ~>
      new Vec2 e.clientX, e.clientY

    onMouseUp = ~>
      stopDrag!
    onMouseMove = (e)~>
      pos = evtPos e
      delta = pos.sub @lastPos
      @el.trigger 'drag', [delta.x, delta.y]
      @lastPos = pos

    startDrag = (e)~>
      @startPos = evtPos e
      $(document).on 'mouseup', onMouseUp
      $(document).on 'mousemove', onMouseMove
      p = @lastPos = @startPos
      @el.trigger 'drag', [0, 0]

    stopDrag = ~>
      if @startPos?
        @startPos = null
        @lastPos = null
        $(document).off 'mouseup', onMouseUp
        $(document).off 'mousemove', onMouseMove

    @el.on 'mousedown', startDrag
  new DragHelper el


SliderView = !->
  @el = $ '<span/>'
    .addClass 'tz-slider'

  @bar = $ '<span/>'
    .addClass 'tz-slider-bar'
    .appendTo @el

  @setValue = (v)~>
    @bar.width (v * 100) + '%'

  drag = makeDraggable @el
  @cleanup = ~>
    drag.cleanup!

  @bar.width '50%'

PropertyView = (prop) !->
  @$el = $ '<div/>'
    .addClass 'property'

  $ '<label/>'
    .text prop.name
    .appendTo @$el

  $prop = $ \<div/>
    .appendTo @$el

  @subs = []

  if prop.range?
    power = prop.power or 1.0
    conv = (v)-> Math.pow(v, power)
    invconv = (v)-> Math.pow(v, 1.0 / power)

    rmin = invconv prop.range[0]
    rmax = invconv prop.range[1]
    range = prop.range.1 - prop.range.0
    sv = new SliderView!
    sv.setValue invconv (prop.value! / range)
    sv.el
      .appendTo $prop
    sv.el.on 'drag', (e, x, y) !->
      prop.value conv(invconv(prop.value!) + (x * range / 500))

    @subscription = prop.value.subscribe (newVal) !->
      $input.val newVal
      sv.setValue invconv (newVal / range)

    $input = $ '<input/>'
      .val prop.value!
      .appendTo $prop
      .addClass 'tz-input'
      .change (evt)->
        if prop.type is 'int'
          prop.value parseInt $input.val!
        else
          prop.value parseFloat $input.val!


  @cleanup = !~>
    @subscription?.dispose!
    #ko.applyBindings prop, $range[0]
  
PropertyGroup = (title)!->
  @$el = $ '<div/>'
    .addClass 'property-group'

  @setProperties = (props) !~>
    @$el.empty()

    $ \<h1/>
      .text title
      .appendTo @$el

    props.forEach (p) !~>
      pv = new PropertyView p
      @$el.append pv.$el


Editor = !->
  @tiling = -> true
  @tool = new RoundBrush this
  @toolObject = -> @tool



start = ->
  editor = new Editor
  doc = new Document 512, 512
  doc.layer.fill -> -1
  view = new DocumentView $('.document-view'), doc, editor
  view.render!

  g = new PropertyGroup 'Tool'
  g.setProperties editor.@tool.properties
  $ \#properties
    .append g.$el


$(document).ready start