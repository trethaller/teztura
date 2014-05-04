RoundBrush = require './roundbrush'
{concat} = require 'prelude-ls'
{createProperties}  = require '../core/properties'

class StepTransform
  @properties = [
  * id: 'step'
    name: "Step %"
    defaultValue: 10
    range: [0, 100]
  ]

  (@editor, @next, @props) ->
    @lastpos = null
    @accumulator = 0.0
    @child = @next!

  step: (pos, pressure) !->
    doc = @editor.doc
    const tiling = @editor.tiling
    const wpos = if tiling then pos.wrap(doc.width, doc.height) else pos.clone!
    const stepSize = Math.max(1, Math.round(@props.step! * @editor.tool.size! / 100.0))

    if @lastpos?
      delt = pos.sub @lastpos
      length = delt.length()
      dir = delt.scale(1.0 / length)
      while @accumulator + stepSize <= length
        @accumulator += stepSize
        p = @lastpos.add dir.scale(@accumulator)
        if tiling
          p := p.wrap doc.width, doc.height
        @child.step p, pressure
      @accumulator -= length
    else
      @child.step wpos, pressure

    @lastpos = pos.clone!

  release: !->
    @lastpos = null
    @accumulator = 0
    @child.release!


class ToolStack
  (editor) ->
    # @tool = new RoundBrush env
    @layer = null
    @doc = editor.doc
    
    props = {}
    createProperties props, StepTransform.properties

    nextFunc = ~> {
      step: (pos, pressure) !~>
        @dirtyRects.push editor.tool.draw @layer, pos, pressure
      release: !-> ;
    }

    @root = new StepTransform editor, nextFunc, props

  draw: (layer, pos, pressure) ->
    @dirtyRects = []
    @layer = layer
    @root.step pos, pressure
    w = @doc.width
    h = @doc.height
    outRects = concat @dirtyRects.map(-> it.wrap w, h)
    return outRects
  endDraw: ->
    @root.release!

export { ToolStack }