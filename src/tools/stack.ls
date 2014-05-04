RoundBrush = require './roundbrush'
{map, concat, filter} = require 'prelude-ls'

/*
class ToolPoint
  (@pos, @pressure, @size) ->;
*/

class StepTransform
  (@doc, @env, @props) ->
    /*
    createProperties @, [
    * id: 'step'
      name: "Step %"
      defaultValue: 10
      range: [0, 100]
    ]
    */

    @lastpos = null
    @accumulator = 0.0
    @tool = @env.tool!

  step: (pos, pressure) !->
    const wpos = if tiling then pos.wrap(@doc.width, @doc.height) else pos.clone!

    const tiling = true # TODO
    const stepSize = 4 # TODO

    if @lastpos?
      delt = pos.sub @lastpos
      length = delt.length()
      dir = delt.scale(1.0 / length)
      while @accumulator + stepSize <= length
        @accumulator += stepSize
        p = @lastpos.add dir.scale(@accumulator)
        if tiling
          p := pos.wrap @doc.width, @doc.height
        @tool.step p, pressure
        # stepFunc layer, pt, pressure, rect
      @accumulator -= length
    else
      # stepFunc layer, wpos, pressure, rect
      @tool.step wpos, pressure

    @lastpos = pos.clone!

  release: !->
    @lastpos = null
    @accumulator = 0
    @tool.release!

/*
class OutTransform 
  (@rects) -> ;
  step: (pos, pressure) !~>
    @rects.push @tool.draw @doc.layer, pos, pressure
  release: !-> ;
*/

class ToolStack
  (@tool, @doc) ->
    # @tool = new RoundBrush env
    @layer = null

    env = {
      tool: ~> {
        step: (pos, pressure) !~>
          @dirtyRects.push @tool.draw @layer, pos, pressure
        release: !-> ;
      }
    }

    @root = new StepTransform @doc, env

  draw: (layer, pos, pressure) ->
    @dirtyRects = []
    @layer = layer
    @root.step pos, pressure
    docrect = @doc.getRect!
    outRects = @dirtyRects
      |> map -> it.wrap docrect
      |> concat
      |> filter -> not it.isEmpty!

    return outRects
  endDraw: ->
    @root.release!

export { ToolStack }