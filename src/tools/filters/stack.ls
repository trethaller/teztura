{fold1, reverse} = require 'prelude-ls'
Rect  = require '../../core/rect'

class FilterStack
  (editor, stack) ->
    @layer = null
    @doc = editor.doc
    
    lastStage = {
      step: (pos, pressure) !~>
        @dirtyRects.push editor.tool.draw @layer, pos, pressure
      release: !-> ;
    }

    nextFunc = (-> lastStage)
    (reverse stack).forEach (def) !->
      nf = nextFunc
      nextFunc := -> new def.type editor, nf, def.props

    @root = nextFunc!

  draw: (layer, pos, pressure) ->
    @dirtyRects = []
    @layer = layer
    @root.step pos, pressure
    w = @doc.width
    h = @doc.height

    if @dirtyRects.length > 0
      dirtyRect = fold1 Rect.union, @dirtyRects
      return dirtyRect.wrap w, h
    else
      return []

  endDraw: ->
    @root.release!

module.exports = FilterStack