(function(){
  var Vec2, Document, DocumentView, RoundBrush, makeDraggable, SliderView, PropertyView, Editor, start;
  Vec2 = require('./core/vec').Vec2;
  Document = require('./document');
  DocumentView = require('./document-view');
  RoundBrush = require('./tools/roundbrush');
  makeDraggable = function(el){
    function DragHelper(el){
      var evtPos, onMouseUp, onMouseMove, startDrag, stopDrag, this$ = this;
      this.el = el;
      this.startPos = null;
      this.lastPos = null;
      this.delta = null;
      this.cleanup = function(){
        stopDrag();
        return this.el.off('mousedown', startDrag);
      };
      evtPos = function(e){
        return new Vec2(e.clientX, e.clientY);
      };
      onMouseUp = function(){
        return stopDrag();
      };
      onMouseMove = function(e){
        var pos, delta;
        pos = evtPos(e);
        delta = pos.sub(this$.lastPos);
        this$.el.trigger('drag', [delta.x, delta.y]);
        return this$.lastPos = pos;
      };
      startDrag = function(e){
        var p;
        this$.startPos = evtPos(e);
        $(document).on('mouseup', onMouseUp);
        $(document).on('mousemove', onMouseMove);
        p = this$.lastPos = this$.startPos;
        return this$.el.trigger('drag', [0, 0]);
      };
      stopDrag = function(){
        if (this$.startPos != null) {
          this$.startPos = null;
          this$.lastPos = null;
          $(document).off('mouseup', onMouseUp);
          return $(document).off('mousemove', onMouseMove);
        }
      };
      return this.el.on('mousedown', startDrag);
    }
    return new DragHelper(el);
  };
  SliderView = function(){
    var drag, this$ = this;
    this.el = $('<span/>').addClass('tz-slider');
    this.bar = $('<span/>').addClass('tz-slider-bar').appendTo(this.el);
    this.setValue = function(v){
      return this$.bar.width(v * 100 + '%');
    };
    drag = makeDraggable(this.el);
    this.cleanup = function(){
      return drag.cleanup();
    };
    this.bar.width('50%');
  };
  PropertyView = function(prop){
    var power, conv, invconv, rmin, rmax, range, $input, sv, this$ = this;
    this.$el = $('<div/>');
    $('<span/>').text(prop.name).appendTo(this.$el);
    this.subs = [];
    if (prop.range != null) {
      power = prop.power || 1.0;
      conv = function(v){
        return Math.pow(v, power);
      };
      invconv = function(v){
        return Math.pow(v, 1.0 / power);
      };
      rmin = invconv(prop.range[0]);
      rmax = invconv(prop.range[1]);
      range = prop.range[1] - prop.range[0];
      $input = $('<input/>').val(prop.value()).appendTo(this.$el).addClass('form-input').change(function(evt){
        if (prop.type === 'int') {
          return prop.value(parseInt($input.val()));
        } else {
          return prop.value(parseFloat($input.val()));
        }
      });
      sv = new SliderView();
      sv.setValue(invconv(prop.value() / range));
      this.$el.append(sv.el);
      sv.el.on('drag', function(e, x, y){
        return prop.value(conv(invconv(prop.value()) + x * range / 500));
      });
      /*
      $slider = $ '<input type="range"/>'
        .attr 'min', rmin
        .attr 'max', rmax
        .attr 'step', if prop.type is 'int' then 1 else (rmax - rmin) / 100
        #.addClass 'topcoat-range'
        .val invconv prop.value!
        .appendTo @$el
        .change (evt)->
          prop.value conv $slider.val!
      */
      this.subscription = prop.value.subscribe(function(newVal){
        $input.val(newVal);
        return sv.setValue(invconv(newVal / range));
      });
    }
    this.cleanup = function(){
      var ref$;
      return (ref$ = this$.subscription) != null ? ref$.dispose() : void 8;
    };
  };
  Editor = function(){
    this.tiling = function(){
      return true;
    };
    this.tool = new RoundBrush(this);
    this.toolObject = function(){
      return this.tool;
    };
    this.tool.properties.forEach(function(p){
      var pv;
      pv = new PropertyView(p);
      return $('#properties').append(pv.$el);
    });
  };
  start = function(){
    var editor, doc, view;
    editor = new Editor;
    doc = new Document(512, 512);
    doc.layer.fill(function(){
      return -1;
    });
    view = new DocumentView($('.document-view'), doc, editor);
    return view.render();
  };
  $(document).ready(start);
}).call(this);
