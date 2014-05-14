
{loadImageData} = require './core/utils'
{createProperties}  = require './core/properties'
Document = require './document'
DocumentView = require './document-view'
RoundBrush = require './tools/roundbrush'
GradientRenderer = require './renderers/gradient'
GammaRenderer = require './renderers/gamma'
{PropertyGroup} = require './property-view'

{SmoothFilter1, InterpolateFilter} = require './tools/filters/basic'
FilterStack = require './tools/filters/stack'



Editor = !->
  @tiling = true

  @tool = new RoundBrush this

  @doc = new Document 512, 512
  @doc.layer.fill -> -1

  stack = [
  * type: SmoothFilter1
    props: createProperties null, SmoothFilter1.properties
  * type: InterpolateFilter
    props: createProperties null, InterpolateFilter.properties
  ]

  stack.0.props.factor 0.5

  transStack = new FilterStack this, stack
  @toolObject = -> transStack

  @view = new DocumentView $('.document-view'), @doc, this

  @renderers = [new t @doc.layer, @view for t in [GammaRenderer, GradientRenderer]]

  # Re-render instantly if any property change
  @renderers.forEach (r) ~>
    r.propertyChanged.subscribe ~>
      @view.render!

  @renderer = ko.observable @renderers.1
  @renderer.subscribe (r) ~>
    @view.renderer = r
    @view.render!
    renderProps.setProperties r.properties

  toolProps = new PropertyGroup 'Tool'
    ..setProperties @tool.properties
    ..$el.appendTo $ \#properties

  
  renderProps = new PropertyGroup 'Renderer'
    ..setProperties @renderer!.properties
    ..$el.appendTo $ \#properties

  @renderer @renderers.0


WebGLViewer = (editor, $parent) !->
  width = 400
  height = 400
  $canvas = $ \<canvas/>
    .attr 'width', width
    .attr 'height', height
    .appendTo $parent
  @canvas = $canvas[0]

  @renderer = new THREE.WebGLRenderer(canvas: @canvas)
    ..setSize(width, height)
    ..setClearColor(0, 1)
    ..antialias = false
    ..autoClear = true

  @scene = new THREE.Scene()
  @camera = new THREE.PerspectiveCamera( 30, width / height, 0.01, 10 )
    ..position.z = 2
    ..position.x = 2
    ..position.y = 2
    ..lookAt(@scene.position)

  boxGeom = new THREE.TorusGeometry( 0.6, 0.4, 20, 30 )

  @texture = new THREE.Texture(editor.view.canvas)
    ..wrapS = THREE.RepeatWrapping
    ..wrapT = THREE.RepeatWrapping
    ..magFilter = THREE.LinearFilter

  editor.doc.changed.subscribe !~>
    @texture.needsUpdate = true
    @render!

  mat = new THREE.MeshPhongMaterial {
    color: new THREE.Color("gray")
    # map: @texture
    bumpMap: @texture
    bumpScale: 0.3
    shininess: 20
  }

  box = new THREE.Mesh( boxGeom, mat )

  @root = new THREE.Object3D()
    ..add box
  @scene.add @root

  light = new THREE.PointLight(0xffffff, 1.5, 10)
    ..position = new THREE.Vector3 2, 2, 2
  @scene.add(light)


  @render = ~>
    @renderer.clearDepth()
    @renderer.render @scene, @camera

  mainLoop = ~>
    @render!
    @root.rotation.y += 0.02
    requestAnimationFrame mainLoop

  @start = mainLoop


start = ->
  editor = new Editor
  webgl = new WebGLViewer editor, $('#webgl')
    ..start!
  ko.applyBindings editor, $('#editor')[0]





$(document).ready start