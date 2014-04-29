
loadImageData = (url, done) !->
  imageObj = new Image()
  imageObj.onload = ->
    canvas = document.createElement "canvas"
    canvas.width = this.width
    canvas.height = this.height
    ctx = canvas.getContext '2d'
    ctx.drawImage(this, 0, 0)
    imageData = ctx.getImageData(0,0,this.width,this.height)
    done imageData
  imageObj.src = url


event = ->
  subs = []
  f = (...args) !->
    subs.forEach (sub) ->
      sub ...args
  f.subscribe = (s) ->
    subs.push s
  f.unsubscribe = (s) ->
    idx = subs.indexOf s
    if idx > -1
      subs.splice(idx, 1)
  return f

export { event, loadImageData }