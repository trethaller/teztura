{fold1, reverse} = require 'prelude-ls'
Rect  = require '../../core/rect'

class FilterStack
  (editor, stack) ->
    @layer = null
    @previewCtx = null
    @doc = editor.doc
    
    @drawStep = (pos, pressure) !~>
      @dirtyRects.push editor.tool.draw @layer, pos, pressure

    @previewStep = (pos, pressure) !~>
      editor.tool.preview @previewCtx, pos

    @outStage = {
      step: !->;
      release: !->;
    }

    nextFunc = ~> @outStage
    (reverse stack).forEach (def) !->
      nf = nextFunc
      nextFunc := -> new def.type editor, nf, def

    @root = nextFunc!

  draw: (layer, pos, pressure) ->
    @dirtyRects = []
    @layer = layer
    @outStage.step = @drawStep
    @root.step pos, pressure
    w = @doc.width
    h = @doc.height

    if @dirtyRects.length > 0
      dirtyRect = fold1 Rect.union, @dirtyRects
      return dirtyRect.wrap w, h
    else
      return []

  preview: (context, pos) ->
    @previewCtx = context
    @outStage.step = @previewStep
    @root.step pos, 1.0
    @root.release()
    @previewCtx = null

  endDraw: ->
    @root.release!

module.exports = FilterStack