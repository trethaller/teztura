App = Ember.Application.create
  LOG_TRANSITIONS: true,
  LOG_ACTIVE_GENERATION: true

Ember.LOG_BINDINGS = true
Ember.LOG_VIEW_LOOKUPS = true
Ember.ENV.RAISE_ON_DEPRECATION = true

App.Router.map ()->
  this.resource('editor', { path: '/' })


App.DocumentController = Ember.Controller.extend
  drawing: false
  tiling: true
  
  context: null
  layer: null
  dirtyRects: null

  startDrawing: ()->
    @set("drawing", true)
    console.log "start drawing"

  stopDrawing: ()->
    @set("drawing", false)
    console.log "stop drawing"

  mouseMove: (x,y)->
    if @get('drawing')
      console.log "drawing"

App.DocumentView = Ember.View.extend
  templateName: 'document-view'
  context: null

  dirtyRectsChanged: (()->
    rects = @get('controller.dirtyRects')
    if rects?
      renderRects(rects)
    @get('controller').set('dirtyRects', null)
  ).observes('controller.dirtyRects')

  renderRects: (rects)->
    ctx = @get('context')
    layer = @get('controller.layer')
    for rect in rects
      ctx.drawImage(layer.canvas,
        rect.x, rect.y, rect.width+1, rect.height+1,
        rect.x, rect.y, rect.width+1, rect.height+1)

  didInsertElement: ()->
    self = this
    layer = @get('controller.layer')

    $canvas = $('<canvas/>',{'class':''}).attr {width: layer.width, height:layer.height}
    this.$().addClass('document-view')
    this.$().append($canvas)

    context = $canvas[0].getContext('2d')
    context.fillRect(10,10,10,10)
    @get('controller').set('context', context)
    
    self.$().mousedown (e)->
      e.preventDefault()
      if e.which is 1
        self.get('controller').send('startDrawing')
    
    self.$().mouseup (e)->
      if e.which is 1
        self.get('controller').send('stopDrawing')

    self.$().mousemove (e)->
      x = e.pageX-$canvas.position().left
      y = e.pageY-$canvas.position().top
      if e.which is 1
        self.get('controller').send('mouseMove', x, y)

    return


doc = App.DocumentController.create(
  layer: new Layer(512, 512))


App.EditorRoute = Ember.Route.extend
  model: ()->
    return {
      document: doc
    }
