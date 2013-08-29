
class Document
  constructor: (@width,@height)->
    @layer = new Layer(@width,@height)
    @backup = new Layer(@width,@height)
    @history = []
    @histIndex = 1

  beginEdit: ->
    if @histIndex > 0
      # Discard obsolete history branch
      @history.splice 0, @histIndex
      @histIndex = 0

      # Backup layer, which becomes the head
      @backup.getBuffer().set(@layer.getBuffer())

  afterEdit: (rect)->
    
    # Insert item at the top
    @history.splice 0, 0, {
      data: @backup.getCopy(rect)
      rect: rect
    }

    # Backup current layer
    @backup.getBuffer().set(@layer.getBuffer())

    # Limit history
    histSize = 10
    if @history.length >= histSize
      @history.splice(histSize)

  undo: ->
    if @histIndex >= @history.length
      return
      
    @restore()
    @histIndex++

  redo: ->
    if @histIndex is 0
      return

    @histIndex--
    @restore()

  restore: ->
    toRestore = @history[ @histIndex ]

    # Backup what we are going to undo
    rect = toRestore.rect
    @history[ @histIndex ] = {
      data: @layer.getCopy(rect)
      rect: rect
    }

    @layer.setData(toRestore.data, toRestore.rect)
