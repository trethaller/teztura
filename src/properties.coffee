
PropertyView = Backbone.View.extend
  className: "property"

  initialize: () ->
    tool = @model.tool
    prop = @model.prop

    # Label
    $('<span/>').text(prop.name).appendTo(@$el)

    # Slider
    if prop.range?
      power = prop.power or 1.0
      conv = (v)-> Math.pow(v, power)
      invconv = (v)-> Math.pow(v, 1.0 / power)
      
      rmin = invconv(prop.range[0])
      rmax = invconv(prop.range[1])
      step = if prop.type is 'int' then 1 else (rmax-rmin) / 100

      $slider = $('<div/>').slider({
        min: rmin
        max: rmax
        value: invconv(tool.get(prop.id))
        step: step
        change: (evt, ui)->
          tool.set(prop.id, conv(ui.value))
          editor.setToolDirty()
      }).width(200).appendTo(@$el)

      $input = $('<input/>')
        .val(tool.get(prop.id))
        .appendTo(@$el)
        .change (evt)->
          if prop.type is 'int'
            tool.set(prop.id, parseInt($input.val()))
          else
            tool.set(prop.id, parseFloat($input.val()))

      @listenTo @model.tool, "change:#{prop.id}", ()->
        v = tool.get(prop.id)
        $input.val(v)
        $slider.slider("value", invconv(v))


class PropertyPanel
  constructor: (@selector)->
    @views = []

  setTool: (tool)->
    @removeViews()
    tool.properties.forEach (prop)=>
      v = new PropertyView
        model: {prop, tool}

      $(@selector).append(v.$el)
      @views.push(v)

  removeViews: ()->
    @views.forEach (v)->
      v.remove()
    @views = []
