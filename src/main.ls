
{loadImageData} = require './core/utils'
Document = require './document'
DocumentView = require './document-view'
RoundBrush = require './tools/roundbrush'
GradientRenderer = require './renderers/gradient'
GammaRenderer = require './renderers/gamma'
{PropertyGroup} = require './property-view'


Editor = !->
  @tiling = -> true
  @tool = new RoundBrush this
  @toolObject = -> @tool

  @doc = new Document 512, 512
  @doc.layer.fill -> -1

  @view = new DocumentView $('.document-view'), @doc, this

  @renderers = [new t @doc.layer, @view for t in [GammaRenderer, GradientRenderer]]
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