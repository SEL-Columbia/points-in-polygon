var app = app || {};

jQuery(function($){
  // Areas' collection
  // pointSet, layerId, legend, pointsTableName, app.style, areaIds
  app.AreaSet = Backbone.Collection.extend({
    initialize: function() {
      this.on('reset', function(collection, options) {
        this.levelAreas = this.levelAreas || {};
        if(!this.levelAreas.hasOwnProperty(this.breadcrumb.level)) {
          this.levelAreas[this.breadcrumb.level] = options.previousModels;
        }
      });
    },

    queryPoints: function() {
      app.loading.start();
      var pointSet = this.pointSet;
      var points = [];
      pointSet.each(function(p){
        if(p.get('isExisted') && p.get('isSelected')) {
          points.push(p.get('tableIndex'));
        }
      });

      var that = this;
      if(this.areaIds)  {
        $.post('/api/query_points_count_of_areas', {area_ids: this.areaIds, points: points, table_name: this.pointsTableName}, function(data) {
          that.legend.update(data);
          app.loading.stop();
        });
      } else {
        $.post('/api/query_points_count_of_layer_areas', {layer_id: this.layerId, points: points, table_name: this.pointsTableName}, function(data) {
          that.legend.update(data);
          app.loading.stop();
        });
      }
    },

    expandArea: function(areaId) {
      app.loading.start();
      var that = this;
      this.breadcrumb.recordClick({areaId: areaId, layerId: this.layerId, tableName: this.pointsTableName, grades: this.legend.get('grades')});

      $.post('/api/find_layer_children', {layer_id: this.layerId, area_id: areaId, table_name: this.pointsTableName}, function(data){
        var newAreas = data.children;
        var counts = data.counts;
        var points = data.points;
        var isPenultimate = data.is_penultimate;
        that.layerId = data.layer_id;

        if(newAreas && counts) {
          that.replaceAreas(newAreas, counts, isPenultimate);
        }

        //if(isPenultimate) {
        that.pointSet.resetPoints();
        that.pointSet.activePoints(_.values(_.flatten(_.values(points))));
        that.areaIds = _.keys(counts);
        //}
        that.filterPanelView.hide();

        that.breadcrumb.expand();
        $('.leaflet-control-layers-base input:checked').prop('checked', false);
        $('.leaflet-control-layers-base input:first').prop('checked', true);

        app.loading.stop();
      });
    },

    replaceAreas: function(newAreas, counts, isPenultimate) {
      var pointsCountOfAreas = _.values(counts);
      var grades = app.style.getColorGrade(pointsCountOfAreas);
      var areas = [];
      this.removeAllFromLayer();
      var showWay = this.at(0).get('showWay');
      for(var k in newAreas) {
        if(newAreas.hasOwnProperty(k)) {
          var border = newAreas[k];
          var count = counts[k];
          var area = new app.Area({border: border, count: count, totalCount: count, areaId: k, pointSet: this.pointSet, areaSet: this, clicked: false, canShowPoints: isPenultimate, canExpandChild: !isPenultimate, showWay: showWay}, {grades: grades});
          areas.push(area);
          area.get('lArea').addTo(this.lLayerGroup);
        }
      }
      this.reset(areas);

      this.legend.set({grades: grades, areaSet: this});
    },

    removeAllFromLayer: function() {
      var that = this;
      this.each(function(a) {
        that.lLayerGroup.removeLayer(a.get('lArea'));
      });
    },

    goback: function(level, layerId, grades) {
      var newAreas = this.levelAreas[level];

      this.removeAllFromLayer();
      var that = this;

      var areaIds = [];
      _.each(newAreas, function(area) {
        area.get('lArea').addTo(that.lLayerGroup);
        areaIds.push(area.get('areaId'));
        var showWay = that.at(0).get('showWay');
        area.set('showWay', showWay);
        if(showWay == 'percentage') {
          area.setPercentageStyle();
        }
      });

      this.reset(newAreas);
      this.areaIds = areaIds;
      this.legend.set({grades: grades, areaSet: this});
      this.layerId = layerId;
    },

    legendShowChange: function(nowWay) {
      var style = null;
      this.each(function(a) {
        if(nowWay == 'percentage') {
          a.setPercentageStyle();
        } else {
          a.setStyle(a.get('magnitudeStyle'));
        }
        a.set('showWay', nowWay);
      });
    }
  });
});
