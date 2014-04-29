(function(){
  var loadImageData, event, ref$, slice$ = [].slice, out$ = typeof exports != 'undefined' && exports || this;
  loadImageData = function(url, done){
    var imageObj;
    imageObj = new Image();
    imageObj.onload = function(){
      var canvas, ctx, imageData;
      canvas = document.createElement("canvas");
      canvas.width = this.width;
      canvas.height = this.height;
      ctx = canvas.getContext('2d');
      ctx.drawImage(this, 0, 0);
      imageData = ctx.getImageData(0, 0, this.width, this.height);
      return done(imageData);
    };
    imageObj.src = url;
  };
  event = function(){
    var subs, f;
    subs = [];
    f = function(){
      var args;
      args = slice$.call(arguments);
      subs.forEach(function(sub){
        return sub.apply(null, args);
      });
    };
    f.subscribe = function(s){
      return subs.push(s);
    };
    f.unsubscribe = function(s){
      var idx;
      idx = subs.indexOf(s);
      if (idx > -1) {
        return subs.splice(idx, 1);
      }
    };
    return f;
  };
  ref$ = out$;
  ref$.event = event;
  ref$.loadImageData = loadImageData;
}).call(this);
