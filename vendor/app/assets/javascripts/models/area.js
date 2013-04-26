var app = app || {};

jQuery(function($){
  // Area model
  // Attrs: border, count, color, style, pointSet, areaSet, clicked, canShowPoints, canExpandChild
  var gPopup = null;
  var countInArea = 0;
  app.Area = Backbone.Model.extend({
    defaults: {
      clicked: true
    },

    initialize: function(attrs, options) {
      var style = app.style.getStyle(this.get('count'), options.grades);
      this.set('magnitudeStyle', style);
      if(this.get('showWay') == "percentage") {
        var percent = this.calPercentage();
        style = app.style.getPercentageStyle(percent);
      }
      var area = null;
      var border = this.get('border');

      if(border.length > 0 && border[0].length > 0 && Array.isArray(border[0][0])) {
        area = L.multiPolygon(border, style);
      } else {
        area = L.polygon(border, style);
      }

      area.on('mouseout', this.resetHighlight, this);

      area.on('click', this.zoomToFeature, this);
      area.on('mouseover', this.highlightFeature, this);

      area.areaId = this.get('areaId');

      this.set({
        lArea: area,
        style: style
      });
    },

    generateMarker: function(markerGroup) {
      var center = this.get('lArea').getBounds().getCenter();
      var marker = L.marker(center, {
        icon: new L.Icon({
          iconUrl: '/assets/marker-icon.png',
          shadowUrl: '/assets/marker-shadow.png'
        })
      }).addTo(markerGroup);
      marker.bindPopup("<b>Count: " + this.get('count') + "</b>", {offset: new L.Point(12, 9)}).openPopup();
      this.marker = marker;
    },

    setStyle: function(style) {
      if(this.get('showWay') == 'magnitude') {
        this.set('magnitudeStyle', this.get('style'));
      }
      this.set('style', style);
      this.get('lArea').setStyle(style);
      this.get('lArea').originStyle = style;
      this.get('lArea')._options = style;
    },

    setPercentageStyle: function() {
      var percent = this.calPercentage();
      var style = app.style.getPercentageStyle(percent);
      this.setStyle(style);
      countInArea = 0;
    },

    toggleClick: function() {
      if(this.get('clicked')) {
        this.set('clicked', false);
      } else {
        this.set('clicked', true);
      }
    },

    // Listener for clicking event
    zoomToFeature: function(e) {
      app.map.get('lMap').fitBounds(e.target.getBounds());

      if(this.get('canShowPoints')) {
        this.get('pointSet').clickArea(e.target.areaId, this.get('clicked'));
        this.toggleClick();
      }

      if(this.get('canExpandChild')) {
        this.get('areaSet').expandArea(e.target.areaId);
        countInArea = 0;
      }
    },

    // An event listener for layer mouseover
    highlightFeature: function(e) {
      countInArea += 1;
      var layer = e.target;
      // No resetStyle method for polygon, so keep the origin style
      var options = null;
      options = layer._options ? layer._options : layer.options;
      if(options) {
        layer.originStyle = options;

        layer.setStyle(app.style.get('highlight'));
        if(options.fillColor == '#FFEFD0') {
          layer.setStyle({fillColor: '#123'});
        }
      }

      if (!L.Browser.ie && !L.Browser.opera) {
        layer.bringToFront();
      }
      layer.bringToBack();

      this.showInfo(layer);
    },

    showInfo: function(layer) {
      var percent = this.calPercentage();
      var count = this.get('count');
      if (typeof count == 'undefined') {
        count = 0;
      }
      if(this.get('showWay') == "percentage") {
        var popContent = "" + count + " / " + this.get('totalCount') + "(" + percent + "%)";
        if(typeof this.get('totalCount') == 'undefined' || this.get('totalCount') === 0) {
          popContent = "None";
        }
        layer.popup = L.popup()
          .setLatLng(layer.getBounds().getCenter())
          .setContent(popContent);
          //.openOn(app.map.get('lMap'));
        gPopup = layer.popup;
        // FIXME: solve the popup disapear when mouseover on the popup
        setTimeout(function() {
          gPopup.openOn(app.map.get('lMap'));
        }, 300);
      }
    },

    calPercentage: function() {
      var count = this.get('count');
      if (typeof count == 'undefined') {
        count = 0;
      }
      var totalCount = this.get('totalCount');
      if (typeof totalCount == 'undefined' || totalCount === 0) {
        return 0;
      }
      return parseInt(count / totalCount * 100, 10);
    },

    // Listener for mouseout
    resetHighlight: function(e) {
      var layer = e.target;

      countInArea -= 1;

      // Set style of tile layer to the origin style
      layer.setStyle(layer.originStyle);
      //if(layer.popup != gPopup) {
      //  app.map.get('lMap').removeLayer(layer.popup);
      //}}, 500);

      if(this.get('showWay') == "percentage") {
        setTimeout(function() {
          if(countInArea <= 0) {
            app.map.get('lMap').removeLayer(layer.popup);
            countInArea = 0;
          }
        }, 300);
      }
    }
  });

});
