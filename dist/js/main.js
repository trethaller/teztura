(function(){
  var Vec2, loadImageData, Document, DocumentView, RoundBrush, GradientRenderer, PropertyGroup, Editor, start;
  Vec2 = require('./core/vec').Vec2;
  loadImageData = require('./core/utils').loadImageData;
  Document = require('./document');
  DocumentView = require('./document-view');
  RoundBrush = require('./tools/roundbrush');
  GradientRenderer = require('./renderers/gradient');
  PropertyGroup = require('./property-view').PropertyGroup;
  Editor = function(){
    this.tiling = function(){
      return true;
    };
    this.tool = new RoundBrush(this);
    this.toolObject = function(){
      return this.tool;
    };
  };
  start = function(){
    var editor, doc, view, renderer;
    editor = new Editor;
    doc = new Document(512, 512);
    doc.layer.fill(function(){
      return -1;
    });
    view = new DocumentView($('.document-view'), doc, editor);
    renderer = new GradientRenderer(doc.layer, view);
    return loadImageData('/img/gradient-1.png', function(g){
      renderer.gradient(g);
      view.renderer = renderer;
      view.render();
      g = new PropertyGroup('Tool');
      g.setProperties(editor.tool.properties);
      return $('#properties').append(g.$el);
    });
  };
  $(document).ready(start);
}).call(this);
