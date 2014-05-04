
{loadImageData} = require './core/utils'
Document = require './document'
DocumentView = require './document-view'
RoundBrush = require './tools/roundbrush'
GradientRenderer = require './renderers/gradient'
GammaRenderer = require './renderers/gamma'
{PropertyGroup} = require './property-view'
{ToolStack} = require './tools/stack'


Editor = !->
  @tiling = -> true

  @tool = new RoundBrush this

  @doc = new Document 512, 512
  @doc.layer.fill -> -1

  stack = new ToolStack @tool, @doc
  @toolObject = -> stack
  

  /*
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
  */

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