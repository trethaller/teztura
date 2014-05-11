
{loadImageData} = require './core/utils'
{createProperties}  = require './core/properties'
Document = require './document'
DocumentView = require './document-view'
RoundBrush = require './tools/roundbrush'
GradientRenderer = require './renderers/gradient'
GammaRenderer = require './renderers/gamma'
{PropertyGroup} = require './property-view'

{SmoothFilter1, InterpolateFilter} = require './tools/filters/basic'
FilterStack = require './tools/filters/stack'



Editor = !->
  @tiling = true

  @tool = new RoundBrush this

  @doc = new Document 512, 512
  @doc.layer.fill -> -1

  stack = [
  * type: SmoothFilter1
    props: createProperties null, SmoothFilter1.properties
  * type: InterpolateFilter
    props: createProperties null, InterpolateFilter.properties
  ]

  stack.0.props.factor 0.5

  transStack = new FilterStack this, stack
  @toolObject = -> transStack

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

  
  renderProps = new PropertyGroup 'Renderer'
    ..setProperties @renderer!.properties
    ..$el.appendTo $ \#properties

  @renderer @renderers.1


start = ->
  editor = new Editor
  ko.applyBindings editor, $('#editor')[0]

  /*
  renderer = new GradientRenderer doc.layer, view
  g <- loadImageData '/img/gradient-1.png'
  renderer.gradient g
  */


$(document).ready start