var app = app || {};

(function(){
  // Point class, lPoint is the leaflet object
  // attrs:
  //   lat, lon, pointSet(Collection), colValues({col1: value1, col2: value2})
  //   isOnMap(boolean), isExisted(bool), isSelected(boolean), tableIndex
  app.Point = Backbone.Model.extend({
    initialize: function(attrs, options) {
      var latLon = [attrs.lat, attrs.lon],
          color = options.color || 'red',
          fillColor = options.fillColor || 'red',
          radius = options.radius || 300;

      var divNode = document.createElement('DIV');
      //var info = JST['templates/point_info']({row: row});
      //divNode.innerHTML = info;
      var point = L.circle(latLon, radius, {
        color: color,
        fillColor: fillColor,
        fillOpacity: 1
      }); //.bindPopup(divNode, {maxWidth: 1000});
      this.set('lPoint', point);

      point.on('click', this.bindPopup, this);
    },

    bindPopup: function() {
      var that = this;
      $.post('/api/find_point_info', {index: this.get('tableIndex'), table_name: this.get('tableName')}, function(data) {
        var divNode = document.createElement('DIV');
        var info = JST['templates/point_info']({row: data});
        divNode.innerHTML = info;
        that.get('lPoint').bindPopup(divNode, {maxWidth: 1000}).openPopup();
      });
    },

    addTo: function(layer){
      this.get('lPoint').addTo(layer);
    },

    removeFrom: function(layer) {
      layer.removeLayer(this.get('lPoint'));
    },

    hide: function() {
      this.set('isOnMap', false);
    },

    show: function() {
      this.set('isOnMap', true);
    },

    select: function() {
      this.set('isSelected', true);
    },

    unSelect: function() {
      this.set('isSelected', false);
    }

  });
}());
