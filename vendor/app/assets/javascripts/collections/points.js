var app = app || {};

(function(){
  // Set of all points, lLayerGroup is the leaflet object
  // attrs:
  //   colNames([name1, name2]), colColors({col: {attr1: color1, attr2: color2}}), colAttrs, pointsTableName
  app.PointSet = Backbone.Collection.extend({
    generateAttrColors: function(){ //allAttrs) {
      var colColors = {};
      var colAttrs = {};
      _.each(this.colNames, function(col) {
        //var attrs = _.uniq(allAttrs[col]);
        var attrColors = {};
        //_.each(attrs, function(attr) {
        //  var color = app.style.getPrettyColor(attrs.indexOf(attr));
        //  attrColors[attr] = color;
        //});
        colColors[col] = attrColors;
        //colAttrs[col] = colAttrs[col] || [];
        //colAttrs[col] = attrs;
      });
      this.colColors = colColors;
      this.colAttrs = colAttrs;
    },

    switchCol: function(col, attrs, colors) {
      var _this = this;
      var attrs_value = _.values(attrs);
      this.each(function(point){
        if(point.get('isExisted')) {
          var lPoint = point.get('lPoint');
          var color = 'red';
          point.select();
          var index = point.get('tableIndex');
          if(col != 'None' && _.indexOf(attrs_value, attrs[index]) >= 0) {
            //color = _this.colColors[col][point.get('colValues')[col]];
            color = colors[attrs[index]];
            colValues = point.get('colValues');
            _this.colColors[col][attrs[index]] = color;
            colValues[col] = attrs[index];
            point.set('colValues', colValues);
          }
          lPoint.setStyle({
            color: color,
            fillColor: color
          });
        }
      });
    },

    showAll: function() {
      var lLayerGroup = this.lLayerGroup;
      this.each(function(p){
        if(p.get('isExisted')) {
          if(p.get('isOnMap')) {
            lLayerGroup.removeLayer(p.get('lPoint'));
            lLayerGroup.addLayer(p.get('lPoint'));
          }
          //p.show();
          p.select();
        }
      });
    },

    filterPoints: function(col, attr, isActive) {
      var lLayerGroup = this.lLayerGroup;
      var points = [];
      if(isActive) {
        points = this.filter(function(p){
          return p.get('colValues')[col] == attr && !p.get('isSelected') && p.get('isExisted');
        });

        _.each(points, function(p){
          if(p.get('isOnMap')) {
            //p.show();
            lLayerGroup.addLayer(p.get('lPoint'));
          }
          p.select();
        });
      } else {
        points = this.filter(function(p){
          return p.get('colValues')[col] == attr && p.get('isSelected') && p.get('isExisted');
        });

        _.each(points, function(p){
          //p.hide();
          p.unSelect();
          lLayerGroup.removeLayer(p.get('lPoint'));
        });
      }
    },

    selectNoneAttr: function() {
      var lLayerGroup = this.lLayerGroup;
      this.each(function(p) {
        //p.hide();
        if(p.get('isExisted')) {
          p.unSelect();
          lLayerGroup.removeLayer(p.get('lPoint'));
        }
      });
    },

    clickArea: function(areaId, isClicked) {
      //var points = this.filter(function(p){
      //  return p.get('isSelected');
      //});
      var that = this;
      app.loading.start();

      $.post('/api/find_points_within_area', {area_id: areaId, table_name: this.pointsTableName}, function(pointIndexs) {
        if(pointIndexs.length <= 0) {
          app.loading.stop();
          return;
        }
        // Now is clicked, will set unclicked after then
        if(isClicked) {
          that.hidePointsInArea(pointIndexs);
        } else {
          that.showPointsInArea(pointIndexs);
        }
        app.loading.stop();
      });
    },

    activePoints: function(pointIndexs) {
      var that = this;
      that.each(function(p){
        if($.inArray(p.get('tableIndex'), pointIndexs) >= 0){
          p.select();
          p.set('isExisted', true);
          p.get('lPoint').setStyle({
            color: 'red',
            fillColor: 'red'
          });
        }
      });
    },

    resetPoints: function() {
      var that = this;
      that.each(function(p) {
        p.unSelect();
        p.set('isExisted', false);
      });
    },

    showPointsInArea: function(pointIndexs) {
      var that = this;
      that.each(function(p){
        if(p.get('isExisted') && $.inArray(p.get('tableIndex'), pointIndexs) >= 0){
          if(p.get('isSelected')){
            p.addTo(that.lLayerGroup);
          }
          p.show();
        }
      });
    },

    hidePointsInArea: function(pointIndexs) {
      var that = this;
      that.each(function(p){
        if(p.get('isSelected') && $.inArray(p.get('tableIndex'), pointIndexs) >= 0){
          p.removeFrom(that.lLayerGroup);
          p.hide();
        }
      });
    },

    goback: function() {
      var that = this;
      that.each(function(p) {
        p.removeFrom(that.lLayerGroup);
        p.set('isExisted', true);
        p.hide();
        p.select();
        p.get('lPoint').setStyle({
          color: 'red',
          fillColor: 'red'
        });
      });
    }
  });
}());
