
{Vec2} = require './core/vec'
Document = require './document'
DocumentView = require './document-view'
RoundBrush = require './tools/roundbrush'


DragHelper = (@el) !->
  @startPos = null
  @delta = null

  @onStart = (pos)->;
  @onDrag = (pos)->;
  @onStop = (pos)->;

  @cleanup = ->
    stopDrag!
    @el.off 'mousedown', startDrag

  evtPos = (e) ~>
    new Vec2 e.clientX, e.clientY

  onMouseUp = ~>
    stopDrag!
  onMouseMove = (e)~>
    @onDrag (evtPos e).sub @startPos

  startDrag = (e)~>
    @startPos = evtPos e
    $(document).on 'mouseup', onMouseUp
    $(document).on 'mousemove', onMouseMove
    p = @startPos
    @onStart p 
    @onDrag p

  stopDrag = ~>
    if @startPos?
      @startPos = null
      @onStop @delta
      $(document).off 'mouseup', onMouseUp
      $(document).off 'mousemove', onMouseMove

  @el.on 'mousedown', startDrag


SliderView = !->
  @el = $ '<span/>'
    .addClass 'tz-slider'

  @bar = $ '<span/>'
    .addClass 'tz-slider-bar'
    .appendTo @el

  drag = new DragHelper @el
    ..onStart = ~>  console.log 'Start'
    ..onDrag = (d)~> console.log d.x
    ..onStop = (d)~> ;

  @cleanup = ~>
    drag.cleanup!


  @bar.width '50%'

PropertyView = (prop) !->
  @$el = $ '<div/>'
  $ '<span/>'
    .text prop.name

    .appendTo @$el

  @subs = []

  sv = new SliderView!
  @$el.append sv.el

  if prop.range?
    power = prop.power or 1.0
    conv = (v)-> Math.pow(v, power)
    invconv = (v)-> Math.pow(v, 1.0 / power)

    rmin = invconv prop.range[0]
    rmax = invconv prop.range[1]

    $input = $ '<input/>'
      .val prop.value!
      .appendTo @$el
      .addClass 'form-input'
      .change (evt)->
        if prop.type is 'int'
          prop.value parseInt $input.val!
        else
          prop.value parseFloat $input.val!

    $slider = $ '<input type="range"/>'
      .attr 'min', rmin
      .attr 'max', rmax
      .attr 'step', if prop.type is 'int' then 1 else (rmax - rmin) / 100
      #.addClass 'topcoat-range'
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