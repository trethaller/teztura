(function(){
  var createProperties, out$ = typeof exports != 'undefined' && exports || this;
  createProperties = function(target, definitions, changed){
    target.properties = [];
    return definitions.forEach(function(def){
      var prop;
      prop = clone$(def);
      prop.value = ko.observable(def.defaultValue);
      if (changed != null) {
        prop.value.subscribe(function(val){
          return changed(prop.id, val);
        });
      }
      target[prop.id] = prop.value;
      return target.properties.push(prop);
    });
  };
  out$.createProperties = createProperties;
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
}).call(this);
