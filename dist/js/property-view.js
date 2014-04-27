(function(){
  var makeDraggable, SliderView, SliderPropertyView, PropertyView, PropertyGroup, out$ = typeof exports != 'undefined' && exports || this;
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
  SliderPropertyView = function($el, prop){
    var power, conv, invconv, rmin, rmax, range, sv, subscription, $input, this$ = this;
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
    sv = new SliderView();
    sv.setValue(invconv(prop.value() / range));
    sv.el.appendTo($el);
    sv.el.on('drag', function(e, x, y){
      prop.value(conv(invconv(prop.value()) + x * range / 500));
    });
    subscription = prop.value.subscribe(function(newVal){
      $input.val(newVal);
      sv.setValue(invconv(newVal / range));
    });
    $input = $('<input/>').val(prop.value()).appendTo($el).addClass('tz-input').change(function(evt){
      if (prop.type === 'int') {
        return prop.value(parseInt($input.val()));
      } else {
        return prop.value(parseFloat($input.val()));
      }
    });
    this.cleanup = function(){
      return subscription.dispose();
    };
  };
  PropertyView = function(prop){
    var $prop, pv, this$ = this;
    this.$el = $('<div/>').addClass('property');
    $('<label/>').text(prop.name).appendTo(this.$el);
    $prop = $('<div/>').appendTo(this.$el);
    pv = null;
    if (prop.range != null) {
      pv = new SliderPropertyView($prop, prop);
    }
    this.cleanup = function(){
      if (pv != null) {
        pv.cleanup();
      }
    };
  };
  PropertyGroup = function(title){
    var this$ = this;
    this.$el = $('<div/>').addClass('property-group');
    this.setProperties = function(props){
      this$.$el.empty();
      $('<h1/>').text(title).appendTo(this$.$el);
      props.forEach(function(p){
        var pv;
        pv = new PropertyView(p);
        this$.$el.append(pv.$el);
      });
    };
  };
  out$.PropertyGroup = PropertyGroup;
}).call(this);
