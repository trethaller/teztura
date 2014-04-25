
Document = require './document'
DocumentView = require './document-view'
# GammaRenderer = require './renderers/gamma'
RoundBrush = require './tools/roundbrush'




Editor = !->

  @tiling = -> true
  @toolObject = ->
    if not @tool?
      props = {[p.id, p.defaultValue] for p in RoundBrush.properties}
      @tool = RoundBrush.createTool props, this
    @tool

start = ->
  editor = new Editor
  doc = new Document 512, 512
  doc.layer.fill -> -1
  view = new DocumentView $('.document-view'), doc, editor
  view.render!


$(document).ready start