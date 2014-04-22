(function(){
  var Vec2, Rect;
  Vec2 = require('./vec').Vec2;
  Rect = (function(){
    Rect.displayName = 'Rect';
    var prototype = Rect.prototype, constructor = Rect;
    function Rect(x, y, width, height){
      this.x = x;
      this.y = y;
      this.width = width;
      this.height = height;
    }
    prototype.intersect = function(rect){
      var nmaxx, nmaxy, nx, ny;
      nmaxx = Math.min(this.x + this.width, rect.x + rect.width);
      nmaxy = Math.min(this.y + this.height, rect.y + rect.height);
      nx = Math.max(this.x, rect.x);
      ny = Math.max(this.y, rect.y);
      return new Rect(nx, ny, Math.max(0, nmaxx - nx), Math.max(0, nmaxy - ny));
    };
    prototype.union = function(rect){
      var x$;
      x$ = new Rect(this.x, this.y, this.width, this.height);
      x$.extend(rect.topLeft());
      x$.extend(rect.bottomRight());
      return x$;
    };
    prototype.clone = function(){
      return new Rect(this.x, this.y, this.width, this.height);
    };
    prototype.offset = function(vec){
      return new Rect(this.x + vec.x, this.y + vec.y, this.width, this.height);
    };
    prototype.isEmpty = function(){
      return this.width <= 0 || this.height <= 0;
    };
    prototype.round = function(){
      return new Rect(Math.floor(this.x), Math.floor(this.y), Math.ceil(this.width), Math.ceil(this.height));
    };
    prototype.extend = function(obj){
      if (obj.width != null) {
        this.extend(obj.topLeft());
        return this.extend(obj.bottomRight());
      } else {
        if (obj.x < this.x) {
          this.width += this.x - obj.x;
          this.x = obj.x;
        } else {
          this.width = Math.max(this.width, obj.x - this.x);
        }
        if (obj.y < this.y) {
          this.height += this.y - obj.y;
          return this.y = obj.y;
        } else {
          return this.height = Math.max(this.height, obj.y - this.y);
        }
      }
    };
    prototype.topLeft = function(){
      return new Vec2(this.x, this.y);
    };
    prototype.bottomRight = function(){
      return new Vec2(this.x + this.width, this.y + this.height);
    };
    return Rect;
  }());
  Rect.Empty = new Rect(0, 0, 0, 0);
  module.exports = Rect;
}).call(this);
