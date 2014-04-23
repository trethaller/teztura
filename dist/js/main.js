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
      var props, res$, i$, ref$, len$, p;
      if (this.tool == null) {
        res$ = {};
        for (i$ = 0, len$ = (ref$ = RoundBrush.properties).length; i$ < len$; ++i$) {
          p = ref$[i$];
          res$[p.id] = p.defaultValue;
        }
        props = res$;
        this.tool = RoundBrush.createTool(props, this);
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
