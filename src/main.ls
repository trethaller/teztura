
{ Vec2 } = require './core/vec'
{loadImageData} = require './core/utils'
Document = require './document'
DocumentView = require './document-view'
RoundBrush = require './tools/roundbrush'
GradientRenderer  = require './renderers/gradient'
{PropertyGroup} = require './property-view'


Editor = !->
  @tiling = -> true
  @tool = new RoundBrush this
  @toolObject = -> @tool

start = ->
  editor = new Editor
  doc = new Document 512, 512
  doc.layer.fill -> -1

  view = new DocumentView $('.document-view'), doc, editor

  renderer = new GradientRenderer doc.layer, view
  g <- loadImageData '/img/gradient-1.png'
  renderer.gradient g

  view.renderer = renderer
  view.render!

  g = new PropertyGroup 'Tool'
  g.setProperties editor.tool.properties
  $ \#properties
    .append g.$el

$(document).ready start