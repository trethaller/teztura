
view 
  tiling: false
  offset: 0,0
  scale: 1.0
  canvas: null

  renderer
    mode: 'linear'
    gamma: 1.0

  document
    size: {width: 512, height: 512}
    layers
    *dirty: false

Brush
  BrushFace: 'bitmap', 'vector'
  BrushMode: 'add', 'blend', 'flatten', 'blur'...
  


http://www.tartiflop.com/disp2norm/srcview/index.html

Flatten brush
http://mathworld.wolfram.com/Plane.html
N = (a,b,c)
O = (x0, y0, z0)
d = -a.x0 - b.y0 - c.z0
a.x + b.y + c.z + d = 0
c.z = 0 - a.x - b.y - d
z = (-a.x - b.y - d) / c

