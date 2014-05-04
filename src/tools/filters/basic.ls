
class SmoothFilter1
  @properties = [
  * id: 'factor'
    name: "Factor"
    defaultValue: 1.0
    range: [0, 1.0]
  ]

  (@editor, @next, @props) ->
    @pos = null
    @child = @next!

  step: (pos, pressure) !->
    if not @pos?
      @pos = pos
    else
      @pos = @pos.add( pos.sub(@pos).scale(@props.factor!) )
    @child.step @pos, pressure

  release: !->
    @pos = null
    @child.release!


class InterpolateFilter
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


export {
  SmoothFilter1
  InterpolateFilter
}