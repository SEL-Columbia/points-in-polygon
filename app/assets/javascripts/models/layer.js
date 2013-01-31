var app = app || {};

jQuery(function($){
  // Layer model
  // one controls baseLayers and overlayLaers being added.
  // others are all layers based on cols
  // attr: lLayer(leaflet obj)
  // name(colname), pointSet, filterPanel
  app.Layer = Backbone.Model.extend({
    addBackMapLayer: function(map) {
      // The map of the world by leaflet
      var backMapLayer = L.tileLayer('http://{s}.tile.cloudmade.com/42c6e747565540068a4bb4ad883f1f41/997/256/{z}/{x}/{y}.png',
        {attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://cloudmade.com">CloudMade</a>'}
      );
      map.addLayer(backMapLayer);
      this.set('backMapLayer', backMapLayer);
    },

    // Add the layers which are controlled using the radio in the control to map
    addBaseLayerControl: function(baseLayers) {
      return baseLayers;
    },

    addOverlayLayerControl: function(map, overlayLayers) {
      overlayLayers['Map Layer'] = this.get('backMapLayer');

      for(var k in overlayLayers) {
        if(overlayLayers.hasOwnProperty(k)) { // && k != 'Points Layer'
          map.addLayer(overlayLayers[k]);
        }
      }
      return overlayLayers;
    },

    init: function(map, grades, layersGroup) {
      this.addBackMapLayer(map);

      var baseLayers = this.addBaseLayerControl(layersGroup.baseLayers);
      var overlayLayers = this.addOverlayLayerControl(map, layersGroup.overlayLayers);

      L.control.layers(baseLayers, overlayLayers).addTo(map);
    },

    bindOnAdd: function() {
      var lLayer = this.get('lLayer');
      var _this = this;

      lLayer.onAdd = function(map) {
        app.loading.start();
        var filterPanelView = _this.get('filterPanelView');
        var filterPanel = _this.get('filterPanel');
        var name = _this.get('name');
        this._map = map;
        this.eachLayer(map.addLayer, map);
        if(name == 'None') {
          filterPanelView.trigger('noneCol');
        } {
          filterPanel.accessCount(name);
        }
        //_this.get('pointSet').switchCol(name);
        app.loading.stop();
      };
    }
  });
});
