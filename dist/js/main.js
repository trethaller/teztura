(function(){
  var loadImageData, Document, DocumentView, RoundBrush, GradientRenderer, GammaRenderer, PropertyGroup, Editor, start;
  loadImageData = require('./core/utils').loadImageData;
  Document = require('./document');
  DocumentView = require('./document-view');
  RoundBrush = require('./tools/roundbrush');
  GradientRenderer = require('./renderers/gradient');
  GammaRenderer = require('./renderers/gamma');
  PropertyGroup = require('./property-view').PropertyGroup;
  Editor = function(){
    var res$, i$, ref$, len$, t, x$, toolProps, y$, renderProps, this$ = this;
    this.tiling = function(){
      return true;
    };
    this.tool = new RoundBrush(this);
    this.toolObject = function(){
      return this.tool;
    };
    this.doc = new Document(512, 512);
    this.doc.layer.fill(function(){
      return -1;
    });
    this.view = new DocumentView($('.document-view'), this.doc, this);
    res$ = [];
    for (i$ = 0, len$ = (ref$ = [GammaRenderer, GradientRenderer]).length; i$ < len$; ++i$) {
      t = ref$[i$];
      res$.push(new t(this.doc.layer, this.view));
    }
    this.renderers = res$;
    this.renderer = ko.observable(this.renderers[1]);
    this.renderer.subscribe(function(r){
      this$.view.renderer = r;
      this$.view.render();
      return renderProps.setProperties(r.properties);
    });
    x$ = toolProps = new PropertyGroup('Tool');
    x$.setProperties(this.tool.properties);
    x$.$el.appendTo($('#properties'));
    y$ = renderProps = new PropertyGroup('Tool');
    y$.setProperties(this.renderer().properties);
    y$.$el.appendTo($('#properties'));
    this.renderer(this.renderers[0]);
  };
  start = function(){
    var editor;
    editor = new Editor;
    return ko.applyBindings(editor, $('#editor')[0]);
  };
  $(document).ready(start);
}).call(this);
