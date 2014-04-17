(function(){
  var Vec2, Vec3, ref$, out$ = typeof exports != 'undefined' && exports || this;
  Vec2 = (function(){
    Vec2.displayName = 'Vec2';
    var prototype = Vec2.prototype, constructor = Vec2;
    function Vec2(x, y){
      this.x = x;
      this.y = y;
    }
    prototype.clone = function(){
      return new Vec2(this.x, this.y);
    };
    prototype.distanceTo = function(v){
      return Math.sqrt(squareDistanceTo(v));
    };
    prototype.squareDistanceTo = function(v){
      var dx, dy;
      dx = this.x - v.x;
      dy = this.y - v.y;
      return dx * dx + dy * dy;
    };
    prototype.round = function(){
      return new Vec2(Math.round(this.x), Math.round(this.y));
    };
    prototype.add = function(v){
      return new Vec2(this.x + v.x, this.y + v.y);
    };
    prototype.sub = function(v){
      return new Vec2(this.x - v.x, this.y - v.y);
    };
    prototype.scale = function(s){
      return new Vec2(this.x * s, this.y * s);
    };
    prototype.length = function(){
      return Math.sqrt(this.squareLength());
    };
    prototype.squareLength = function(){
      return this.x * this.x + this.y * this.y;
    };
    prototype.normalized = function(){
      return this.scale(1.0 / this.length());
    };
    prototype.wrap = function(w, h){
      return new Vec2((this.x % w + w) % w, (this.y % h + h) % h);
    };
    prototype.toString = function(){
      return this.x + ", " + this.y;
    };
    return Vec2;
  }());
  Vec3 = (function(){
    Vec3.displayName = 'Vec3';
    var prototype = Vec3.prototype, constructor = Vec3;
    function Vec3(x, y, z){
      this.x = x;
      this.y = y;
      this.z = z;
    }
    prototype.add = function(v){
      return new Vec3(this.x + v.x, this.y + v.y, this.z + v.z);
    };
    prototype.sub = function(v){
      return new Vec3(this.x - v.x, this.y - v.y, this.z - v.z);
    };
    prototype.scale = function(s){
      return new Vec3(this.x * s, this.y * s, this.z * s);
    };
    prototype.length = function(){
      return Math.sqrt(this.squareLength());
    };
    prototype.squareLength = function(){
      return this.x * this.x + this.y * this.y + this.z * this.z;
    };
    prototype.normalized = function(){
      return this.scale(1.0 / this.length());
    };
    prototype.cross = function(v){
      return new Vec3(this.y * v.z - this.z * v.y, this.z * v.x - this.x * v.z, this.x * v.y - this.y * v.x);
    };
    prototype.dot = function(v){
      return this.x + v.x + this.y + v.y + this.z + v.z;
    };
    prototype.toString = function(){
      return this.x + ", " + this.y + ", " + this.z;
    };
    return Vec3;
  }());
  ref$ = out$;
  ref$.Vec2 = Vec2;
  ref$.Vec3 = Vec3;
}).call(this);
