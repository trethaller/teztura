{Vec2} = require './core/vec'
Rect = require './core/rect'
GammaRenderer = require './renderers/gamma'


class DocumentView
  drawing: false
  panning: false
  imageData: null
  context: null
  canvas: null
  backContext: null
  doc: null
  offset: new Vec2(0.0, 0.0)
  scale: 2.0
  penPos: new Vec2(0,0)

  ($container, @doc, @editor) ->
    $container.empty()
    $canvas = $('<canvas/>',{'class':''}).attr {width: @doc.width, height:@doc.height}
    $backCanvas = $('<canvas/>',{'class':''}).attr {width: @doc.width, height:@doc.height}
    $container.append($backCanvas)

    @backContext = $backCanvas[0].getContext('2d')
    @canvas = $canvas[0] 
    @context = $canvas[0].getContext('2d')
    @imageData = @context.getImageData(0,0,@doc.width,@doc.height)

    @context.mozImageSmoothingEnabled = false
    @renderer = null

    plugin = document.getElementById('wtPlugin')
    penAPI = plugin?.penAPI

 
    getMouseCoords = (e)~>
      v = new Vec2(e.pageX, e.pageY)

      /*
      penAPI = plugin.penAPI
      if penAPI? and penAPI.pointerType > 0
        v.x += penAPI.sysX - penAPI.posX
        v.y += penAPI.sysY - penAPI.posY
      */
      v.x -= $backCanvas.position().left
      v.y -= $backCanvas.position().top
      return v

    getPressure = ~>
      if penAPI?.pointerType > 0
        return penAPI.pressure
      return 1.0

    updatePen = (e) !~>
      @penPos = getMouseCoords(e)

    getCanvasCoords = ~>
      @screenToCanvas(@penPos)

    $backCanvas.mousedown (e) ~>
      e.preventDefault()

      if e.which is 1
        @drawing = true
        @actionDirtyRect = null
        coords = getCanvasCoords()
        @doc.beginEdit()
        @onDraw(coords, getPressure())

      if e.which is 2
        @panning = true
        @panningStart = getMouseCoords(e)
        @offsetStart = @offset.clone()

    $container.mouseup (e) ~>
      e.preventDefault()
      if e.which is 1
        @editor.toolObject().endDraw()
        @drawing = false
        if @actionDirtyRect?
          @doc.afterEdit(@actionDirtyRect)

      if e.which is 2
        @panning = false

    $container.mousemove (e) ~>
      e.preventDefault()
      updatePen(e)

      if @drawing
        @onDraw(getCanvasCoords(), getPressure())

      if @panning
        curPos = getMouseCoords(e)
        o = @offsetStart.add(curPos.sub(@panningStart))
        @offset = o
        @repaint()

    $container.mousewheel (e, delta, deltaX, deltaY) ~>
      mult = 1.0 + (deltaY * 0.25)
      @scale *= mult
      @repaint()

 
  screenToCanvas: (pt) -> pt.sub(@offset).scale(1.0/@scale)

  render: ->
    @renderer?.render [new Rect(0,0,@doc.width,@doc.height)]
    @repaint()

  repaint: ->
    ctx = @backContext
      ..setTransform(1, 0, 0, 1, 0, 0)
      ..translate(@offset.x, @offset.y)
      ..scale(@scale, @scale)
    
    if @editor.tiling
      ctx.fillStyle = ctx.createPattern(@canvas,"repeat")
      ctx.fillRect(-@offset.x / @scale,-@offset.y / @scale,@canvas.width / @scale, @canvas.height / @scale)
    else
      ctx.drawImage(@canvas, 0, 0)

  onDraw: (pos, pressure) ->

    layer = @doc.layer
    tool = @editor.toolObject()
    dirtyRects = tool.draw(layer, pos, pressure)

    # For undo
    dirtyRects.forEach (r) ~>
      if not @actionDirtyRect?
        @actionDirtyRect = r.round!
      else
        @actionDirtyRect.extend r.round!

    if false # Log dirty rects
      totalArea = dirtyRects
        .map((r) -> r.width * r.height)
        .reduce((a,b) -> a+b)
      console.log "#{dirtyRects.length} rects, #{Math.round(Math.sqrt(totalArea))} px²"

    if true
    #setTimeout (->
      @renderer?.render dirtyRects.map -> it.round!
      @repaint()
    #), 0

module.exports = DocumentView