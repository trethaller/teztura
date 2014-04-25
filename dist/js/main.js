(function(){
  var Document, DocumentView, RoundBrush, Editor, start;
  Document = require('./document');
  DocumentView = require('./document-view');
  RoundBrush = require('./tools/roundbrush');
  Editor = function(){
    this.tiling = function(){
      return true;
    };
    this.toolObject = function(){
      if (this.tool == null) {
        this.tool = new RoundBrush(this);
      }
      return this.tool;
    };
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
