(function(){
  var createProperties, out$ = typeof exports != 'undefined' && exports || this;
  createProperties = function(definitions){
    var i$, len$, p, results$ = {};
    for (i$ = 0, len$ = definitions.length; i$ < len$; ++i$) {
      p = definitions[i$];
      results$[p.id] = p.defaultValue;
    }
    return results$;
  };
  out$.createProperties = createProperties;
}).call(this);
