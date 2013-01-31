var app = app || {};

jQuery(function($){
  app.Map = Backbone.Model.extend({
    createLMap: function(id, center, zoom) {
      this.set({lMap: L.map(id, {
        center: center,
        zoom: zoom
      }) });
    }
  });

  app.map = new app.Map();
});
