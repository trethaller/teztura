App = Ember.Application.create
  LOG_TRANSITIONS: true,
  LOG_ACTIVE_GENERATION: true

Ember.LOG_BINDINGS = true
Ember.LOG_VIEW_LOOKUPS = true
Ember.ENV.RAISE_ON_DEPRECATION = true

App.Router.map ()->
  this.resource('editor', { path: '/' })


App.DocumentController = Ember.Controller.extend
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
  
  didInsertElement: ()->
    self = this
    $canvas = self.$().find('canvas')
    context = $canvas[0].getContext('2d')
    context.fillRect(10,10,10,10)

    self.$().mousedown (e)->
      self.get('document').send('startDrawing')
    
    self.$().mouseup (e)->
      self.get('document').send('stopDrawing')

    self.$().mousemove (e)->
      x = e.pageX-$canvas.position().left
      y = e.pageY-$canvas.position().top
      self.get('document').send('mouseMove', x, y)

    return

doc = App.DocumentController.create()


App.EditorRoute = Ember.Route.extend
  model: ()->
    return {
      document: doc
    }
