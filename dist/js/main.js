(function(){
  var Document, DocumentView, RoundBrush, PropertyView, Editor, start;
  Document = require('./document');
  DocumentView = require('./document-view');
  RoundBrush = require('./tools/roundbrush');
  PropertyView = function(prop){
    var power, conv, invconv, rmin, rmax, $input, $slider, this$ = this;
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
      $input = $('<input/>').val(prop.value()).appendTo(this.$el).change(function(evt){
        if (prop.type === 'int') {
          return prop.value(parseInt($input.val()));
        } else {
          return prop.value(parseFloat($input.val()));
        }
      });
      $slider = $('<input type="range"/>').attr('min', rmin).attr('max', rmax).attr('step', prop.type === 'int'
        ? 1
        : (rmax - rmin) / 100).val(invconv(prop.value())).appendTo(this.$el).change(function(evt){
        return prop.value(conv($slider.val()));
      });
      this.subscription = prop.value.subscribe(function(newVal){
        $input.val(newVal);
        return $slider.val(newVal);
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
