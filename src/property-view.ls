{ Vec2 } = require './core/vec'
{ loadImageData } = require './core/utils'

template = (id) ->
  $($('#tpl-' + id).html!)

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

    @el.on 'mousedown', (e) !->
      e.preventDefault!
      startDrag e

  new DragHelper el


NumberPropertyView = ($el, prop) !->
  power = prop.power or 1.0
  conv = (v)-> Math.pow(v, power)
  invconv = (v)-> Math.pow(v, 1.0 / power)

  rmin = invconv prop.range[0]
  rmax = invconv prop.range[1]
  range = prop.range.1 - prop.range.0

  @el = template 'prop-number'
    .appendTo $el

  @el.find 'label'
    .text prop.name

  $bar = @el.find '.slider-bar'
  $slider = @el.find '.slider-bg'
  drag = makeDraggable $slider
  setVal = (v) !->
    $bar.width (v * 100) + '%'    

  setVal invconv (prop.value! / range)

  $slider.on 'drag', (e, x, y) !->
    prop.value conv(invconv(prop.value!) + (x * range / 500))

  subscription = prop.value.subscribe (newVal) !->
    $input.val newVal
    setVal invconv (newVal / range)

  $input = @el.find 'input'
    .val prop.value!
    # .attr 'step', range/20
    .change (evt) !->
      if prop.type is 'int'
        prop.value parseInt $input.val!
      else
        prop.value parseFloat $input.val!
  
  @cleanup = ~>
    subscription.dispose!
    drag.cleanup!

GradientPropertyView = ($el, prop) !->
  @el = template 'prop-choice'
    .appendTo $el

  @el.find 'label'
    .text prop.name

  @img = $ '<img/>'
    .width '100%'
    .height '4'
    .attr 'src', prop.value
    .appendTo @el.find '.value'

  /*
  sub = prop.value.subscribe (newVal) !~>
    @img.attr 'src', newVal
  */
  
  /*
  $select = $ '<select/>'
    .appendTo $el
    .change (e)->
      img <- loadImageData $select.val!
      prop.value img

  prop.choices.forEach (c)->
    $op = $ \<option/>
      .text c
      .appendTo $select
  */
  @cleanup = ~>;

PropertyView = (prop) !->
  @$el = $ '<div/>'
    .addClass 'property'

  $prop = $ \<div/>
    .appendTo @$el

  pv = null
  if prop.range?
    pv := new NumberPropertyView $prop, prop
  else if prop.type is 'gradient'
    pv := new GradientPropertyView $prop, prop

  @cleanup = !~>
    pv?.cleanup!
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

export { PropertyGroup }