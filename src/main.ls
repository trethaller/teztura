
{loadImageData} = require './core/utils'
Document = require './document'
DocumentView = require './document-view'
RoundBrush = require './tools/roundbrush'
GradientRenderer = require './renderers/gradient'
GammaRenderer = require './renderers/gamma'
{PropertyGroup} = require './property-view'
{map, concat, filter} = require 'prelude-ls'

class ToolPoint
  (@pos, @pressure, @size) ->;

class StepTransform
  (@doc, @env, @props) ->
    /*
    createProperties @, [
    * id: 'step'
      name: "Step %"
      defaultValue: 10
      range: [0, 100]
    ]
    */

    @lastpos = null
    @accumulator = 0.0
    @tool = @env.tool!

  step: (pos, pressure) !->
    const wpos = if tiling then pos.wrap(layer.width, layer.height) else pos.clone!

    const tiling = true # TODO
    const stepSize = 4 # TODO

    if @lastpos?
      delt = pos.sub @lastpos
      length = delt.length()
      dir = delt.scale(1.0 / length)
      while accumulator + stepSize <= length
        accumulator += stepSize
        p = @lastpos.add dir.scale(accumulator)
        if tiling
          p := pos.wrap @doc.width, @doc.height
        @tool.step p, pressure
        # stepFunc layer, pt, pressure, rect
      accumulator -= length
    else
      # stepFunc layer, wpos, pressure, rect
      @tool.step wpos, pressure

    @lastpos = pos.clone!

  release: !->
    @lastpos = null
    @accumulator = 0
    @tool.release!

/*
class OutTransform 
  (@rects) -> ;
  step: (pos, pressure) !~>
    @rects.push @tool.draw @doc.layer, pos, pressure
  release: !-> ;
*/

Editor = !->
  @tiling = -> true

  @tool = new RoundBrush this
  @toolObject = -> @tool

  @doc = new Document 512, 512
  @doc.layer.fill -> -1

  @dirtyRects = null
  env = {
    tool: ~> {
      step: (pos, pressure) !~>
        @dirtyRects.push @tool.draw @doc.layer, pos, pressure
      release: !-> ;
    }
  }

  st = new StepTransform @doc, env

  @draw = (pos, pressure) !~>
    @dirtyRects = []
    st.step pos, pressure
    docrect = @doc.getRect!
    @dirtyRects
      |> map r -> r.wrap docrect
      |> concat
      |> filter r -> not r.isEmpty!

  @endDraw = 
    st.release!

  @view = new DocumentView $('.document-view'), @doc, this

  @renderers = [new t @doc.layer, @view for t in [GammaRenderer, GradientRenderer]]

  # Re-render instantly if any property change
  @renderers.forEach (r) ~>
    r.propertyChanged.subscribe ~>
      @view.render!

  @renderer = ko.observable @renderers.1
  @renderer.subscribe (r) ~>
    @view.renderer = r
    @view.render!
    renderProps.setProperties r.properties

  toolProps = new PropertyGroup 'Tool'
    ..setProperties @tool.properties
    ..$el.appendTo $ \#properties

  renderProps = new PropertyGroup 'Tool'
    ..setProperties @renderer!.properties
    ..$el.appendTo $ \#properties

  @renderer @renderers.0


start = ->
  editor = new Editor
  ko.applyBindings editor, $('#editor')[0]

  /*
  renderer = new GradientRenderer doc.layer, view
  g <- loadImageData '/img/gradient-1.png'
  renderer.gradient g
  */


$(document).ready start