
Document = require './document'
DocumentView = require './document-view'
RoundBrush = require './tools/roundbrush'


Editor = !->
  @tiling = -> true
  @toolObject = ->
    if not @tool?
      @tool = new RoundBrush this
    @tool

start = ->
  editor = new Editor
  doc = new Document 512, 512
  doc.layer.fill -> -1
  view = new DocumentView $('.document-view'), doc, editor
  view.render!

$(document).ready start