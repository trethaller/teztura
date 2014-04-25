(function(){
  var createProperties, out$ = typeof exports != 'undefined' && exports || this;
  createProperties = function(target, definitions, changed){
    target.properties = {};
    return definitions.forEach(function(def){
      var prop;
      prop = clone$(def);
      prop.val = def.defaultValue;
      prop.set = function(val){
        var prev;
        prev = prop.val;
        prop.val = val;
        if (changed != null) {
          return changed(prop.id, val, prev);
        }
      };
      prop.get = function(){
        return prop.val;
      };
      target[prop.id] = function(val){
        if (val != null) {
          return prop.set(val);
        } else {
          return prop.get();
        }
      };
      return target.properties[prop.id] = prop;
    });
  };
  out$.createProperties = createProperties;
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
}).call(this);
