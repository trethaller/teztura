
Document = require './document'
DocumentView = require './document-view'
GammaRenderer = require './renderers/gamma-renderer'
RoundBrush = require './tools/roundbrush'


Editor = !->

  @tiling = -> false
  @toolObject = ->
    if not @tool?
      props = {[p.id, p.defaultValue] for p in RoundBrush.properties}
      @tool = RoundBrush.createTool props, this
    @tool

start = ->
  editor = new Editor
  doc = new Document 512, 512
  doc.layer.fill -> -1
  renderer = GammaRenderer
  view = new DocumentView $('.document-view'), doc, renderer, editor
  view.reRender!


$(document).ready start