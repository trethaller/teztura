
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

SliderPropertyView = ($el, prop) !->
  power = prop.power or 1.0
  conv = (v)-> Math.pow(v, power)
  invconv = (v)-> Math.pow(v, 1.0 / power)

  rmin = invconv prop.range[0]
  rmax = invconv prop.range[1]
  range = prop.range.1 - prop.range.0
  sv = new SliderView!
  sv.setValue invconv (prop.value! / range)
  sv.el
    .appendTo $el
  sv.el.on 'drag', (e, x, y) !->
    prop.value conv(invconv(prop.value!) + (x * range / 500))

  subscription = prop.value.subscribe (newVal) !->
    $input.val newVal
    sv.setValue invconv (newVal / range)

  $input = $ '<input/>'
    .val prop.value!
    .appendTo $el
    .addClass 'tz-input'
    .change (evt)->
      if prop.type is 'int'
        prop.value parseInt $input.val!
      else
        prop.value parseFloat $input.val!
  
  @cleanup = ~>
    subscription.dispose!

PropertyView = (prop) !->
  @$el = $ '<div/>'
    .addClass 'property'

  $ '<label/>'
    .text prop.name
    .appendTo @$el

  $prop = $ \<div/>
    .appendTo @$el

  pv = null
  if prop.range?
    pv := new SliderPropertyView $prop, prop


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