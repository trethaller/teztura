(function(){
  var loadImageData, out$ = typeof exports != 'undefined' && exports || this;
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
  out$.loadImageData = loadImageData;
}).call(this);
