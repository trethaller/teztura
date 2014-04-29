(function(){
  var event, createProperties, out$ = typeof exports != 'undefined' && exports || this;
  event = require('../core/utils').event;
  createProperties = function(target, definitions){
    target.properties = [];
    target.propertyChanged = event();
    return definitions.forEach(function(def){
      var prop;
      prop = clone$(def);
      prop.value = ko.observable(def.defaultValue);
      prop.value.subscribe(function(val){
        return target.propertyChanged(prop.id, val);
      });
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
