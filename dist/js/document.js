(function(){
  var Layer, Document;
  Layer = require('./core/layer');
  Document = (function(){
    Document.displayName = 'Document';
    var prototype = Document.prototype, constructor = Document;
    function Document(width, height){
      this.width = width;
      this.height = height;
      this.layer = new Layer(this.width, this.height);
      this.backup = new Layer(this.width, this.height);
      this.history = [];
      this.histIndex = 1;
    }
    prototype.beginEdit = function(){
      if (this.histIndex > 0) {
        this.history.splice(0, this.histIndex);
        this.histIndex = 0;
        return this.backup.getBuffer().set(this.layer.getBuffer());
      }
    };
    prototype.afterEdit = function(rect){
      var histSize;
      this.history.splice(0, 0, {
        data: this.backup.getCopy(rect),
        rect: rect
      });
      this.backup.getBuffer().set(this.layer.getBuffer());
      histSize = 10;
      if (this.history.length >= histSize) {
        return this.history.splice(histSize);
      }
    };
    prototype.undo = function(){
      if (this.histIndex >= this.history.length) {
        return;
      }
      this.restore();
      return this.histIndex++;
    };
    prototype.redo = function(){
      if (this.histIndex === 0) {
        return;
      }
      this.histIndex--;
      return this.restore();
    };
    prototype.restore = function(){
      var toRestore, rect;
      toRestore = this.history[this.histIndex];
      rect = toRestore.rect;
      this.history[this.histIndex] = {
        data: this.layer.getCopy(rect),
        rect: rect
      };
      return this.layer.setData(toRestore.data, toRestore.rect);
    };
    return Document;
  }());
  module.exports = Document;
}).call(this);
