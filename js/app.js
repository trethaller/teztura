App = Ember.Application.create({
  LOG_TRANSITIONS: true,
  LOG_ACTIVE_GENERATION: true
});

Ember.LOG_BINDINGS = true;
Ember.LOG_VIEW_LOOKUPS = true;
Ember.ENV.RAISE_ON_DEPRECATION = true;

App.Router.map(function() {
  this.resource('editor', { path: '/' });
});

App.EditorRoute = Ember.Route.extend({
  model: function() {
    return {};
  }
});
