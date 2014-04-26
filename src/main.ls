
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
    range = prop.range.1 - prop.range.0

    $input = $ '<input/>'
      .val prop.value!
      .appendTo @$el
      .addClass 'form-input'
      .change (evt)->
        if prop.type is 'int'
          prop.value parseInt $input.val!
        else
          prop.value parseFloat $input.val!

    sv = new SliderView!
    sv.setValue invconv (prop.value! / range)
    @$el.append sv.el
    sv.el.on 'drag', (e, x, y)->
      prop.value conv(invconv(prop.value!) + (x * range / 500))

    /*
    $slider = $ '<input type="range"/>'
      .attr 'min', rmin
      .attr 'max', rmax
      .attr 'step', if prop.type is 'int' then 1 else (rmax - rmin) / 100
      #.addClass 'topcoat-range'
      .val invconv prop.value!
      .appendTo @$el
      .change (evt)->
        prop.value conv $slider.val!
    */

    @subscription = prop.value.subscribe (newVal) ->
      $input.val newVal
      sv.setValue invconv (newVal / range)

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