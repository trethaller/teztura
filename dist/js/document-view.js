(function(){
  var Vec2, Rect, GammaRenderer, DocumentView;
  Vec2 = require('./core/vec').Vec2;
  Rect = require('./core/rect');
  GammaRenderer = require('./renderers/gamma');
  DocumentView = (function(){
    DocumentView.displayName = 'DocumentView';
    var prototype = DocumentView.prototype, constructor = DocumentView;
    prototype.drawing = false;
    prototype.panning = false;
    prototype.imageData = null;
    prototype.context = null;
    prototype.canvas = null;
    prototype.backContext = null;
    prototype.doc = null;
    prototype.offset = new Vec2(0.0, 0.0);
    prototype.scale = 2.0;
    prototype.penPos = new Vec2(0, 0);
    function DocumentView($container, doc, editor){
      var $canvas, $backCanvas, plugin, penAPI, getMouseCoords, getPressure, updatePen, getCanvasCoords, this$ = this;
      this.doc = doc;
      this.editor = editor;
      $container.empty();
      $canvas = $('<canvas/>', {
        'class': ''
      }).attr({
        width: this.doc.width,
        height: this.doc.height
      });
      $backCanvas = $('<canvas/>', {
        'class': ''
      }).attr({
        width: this.doc.width,
        height: this.doc.height
      });
      $container.append($backCanvas);
      this.backContext = $backCanvas[0].getContext('2d');
      this.canvas = $canvas[0];
      this.context = $canvas[0].getContext('2d');
      this.imageData = this.context.getImageData(0, 0, this.doc.width, this.doc.height);
      this.context.mozImageSmoothingEnabled = false;
      this.renderer = null;
      plugin = document.getElementById('wtPlugin');
      penAPI = plugin != null ? plugin.penAPI : void 8;
      getMouseCoords = function(e){
        var v;
        v = new Vec2(e.pageX, e.pageY);
        /*
        penAPI = plugin.penAPI
        if penAPI? and penAPI.pointerType > 0
          v.x += penAPI.sysX - penAPI.posX
          v.y += penAPI.sysY - penAPI.posY
        */
        v.x -= $backCanvas.position().left;
        v.y -= $backCanvas.position().top;
        return v;
      };
      getPressure = function(){
        if ((penAPI != null ? penAPI.pointerType : void 8) > 0) {
          return penAPI.pressure;
        }
        return 1.0;
      };
      updatePen = function(e){
        var pos;
        pos = getMouseCoords(e);
        this$.penPos = this$.penPos.add(pos.sub(this$.penPos).scale(0.6));
      };
      getCanvasCoords = function(){
        return this$.screenToCanvas(this$.penPos);
      };
      $backCanvas.mousedown(function(e){
        var coords;
        e.preventDefault();
        if (e.which === 1) {
          this$.drawing = true;
          this$.actionDirtyRect = null;
          coords = getCanvasCoords();
          this$.doc.beginEdit();
          this$.onDraw(coords, getPressure());
        }
        if (e.which === 2) {
          this$.panning = true;
          this$.panningStart = getMouseCoords(e);
          return this$.offsetStart = this$.offset.clone();
        }
      });
      $container.mouseup(function(e){
        e.preventDefault();
        if (e.which === 1) {
          this$.editor.toolObject().endDraw();
          this$.drawing = false;
          if (this$.actionDirtyRect != null) {
            this$.doc.afterEdit(this$.actionDirtyRect);
          }
        }
        if (e.which === 2) {
          return this$.panning = false;
        }
      });
      $container.mousemove(function(e){
        var curPos, o;
        e.preventDefault();
        updatePen(e);
        if (this$.drawing) {
          this$.onDraw(getCanvasCoords(), getPressure());
        }
        if (this$.panning) {
          curPos = getMouseCoords(e);
          o = this$.offsetStart.add(curPos.sub(this$.panningStart));
          this$.offset = o;
          return this$.repaint();
        }
      });
      $container.mousewheel(function(e, delta, deltaX, deltaY){
        var mult;
        mult = 1.0 + deltaY * 0.25;
        this$.scale *= mult;
        return this$.repaint();
      });
    }
    prototype.screenToCanvas = function(pt){
      return pt.sub(this.offset).scale(1.0 / this.scale);
    };
    prototype.render = function(){
      var ref$;
      if ((ref$ = this.renderer) != null) {
        ref$.render([new Rect(0, 0, this.doc.width, this.doc.height)]);
      }
      return this.repaint();
    };
    prototype.repaint = function(){
      var x$, ctx;
      x$ = ctx = this.backContext;
      x$.setTransform(1, 0, 0, 1, 0, 0);
      x$.translate(this.offset.x, this.offset.y);
      x$.scale(this.scale, this.scale);
      if (this.editor.tiling()) {
        ctx.fillStyle = ctx.createPattern(this.canvas, "repeat");
        return ctx.fillRect(-this.offset.x / this.scale, -this.offset.y / this.scale, this.canvas.width / this.scale, this.canvas.height / this.scale);
      } else {
        return ctx.drawImage(this.canvas, 0, 0);
      }
    };
    prototype.onDraw = function(pos, pressure){
      var layer, tool, layerRect, dirtyRects, totalArea, ref$, this$ = this;
      layer = this.doc.layer;
      tool = this.editor.toolObject();
      layerRect = layer.getRect();
      dirtyRects = tool.draw(layer, pos, pressure);
      dirtyRects.forEach(function(r){
        if (this$.actionDirtyRect == null) {
          return this$.actionDirtyRect = r.round();
        } else {
          return this$.actionDirtyRect.extend(r.round());
        }
      });
      if (false) {
        totalArea = dirtyRects.map(function(r){
          return r.width * r.height;
        }).reduce(function(a, b){
          return a + b;
        });
        console.log(dirtyRects.length + " rects, " + Math.round(Math.sqrt(totalArea)) + " px²");
      }
      if (true) {
        if ((ref$ = this.renderer) != null) {
          ref$.render(dirtyRects.map(function(it){
            return it.round();
          }));
        }
        return this.repaint();
      }
    };
    return DocumentView;
  }());
  module.exports = DocumentView;
}).call(this);
