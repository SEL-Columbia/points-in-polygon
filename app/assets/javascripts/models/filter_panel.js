var app = app || {};

(function(){
  // Filter Panel
  // col, attrAndCount, pointSet, areaSet
  app.FilterPanel = Backbone.Model.extend({
    accessCount: function(colName) {
      app.loading.start();
      var pointSet = this.get('pointSet');
      //var colColors = pointSet.colColors[colName];
      var colCounts = {};
      var entries = [];
      //var cols = pointSet.colAttrs[colName];

      var pointIndexes = [];
      pointSet.each(function(p) {
        if(p.get('isExisted')) {
          //var attr = p.get('colValues')[colName];
          //if(_.indexOf(cols, attr) >= 0) {
          //  colCounts[attr] = colCounts[attr] || 0;
          //  colCounts[attr] += 1;
          //}
          pointIndexes.push(p.get('tableIndex'));
        }
      });
      var that = this;
      that.set('col', colName);
      $.post('/api/find_filters_info', {row_indexes: pointIndexes, col_name: colName, table_name: this.get('pointsTableName')}, function(data) {
        var counts = data.count_of_attrs;
        var attrs_of_points = data.attrs_of_points;
        var attrs = _.keys(counts);
        var colors_of_attrs = {};
        for(var k in counts) {
          if(counts.hasOwnProperty(k)) {
            color = app.style.getPrettyColor(_.indexOf(attrs, k));
            entries.push([color, k, counts[k]]);
            colors_of_attrs[k] = color;
          }
        }
        that.get('pointSet').switchCol(colName, attrs_of_points, colors_of_attrs);
        that.get('view').show(colName, entries);

        that.updateLegend();
        app.loading.stop();
      });
      // when switch colLayer, all points should be shown
      //pointSet.showAll();
      //return entries;
    },

    filterPoints: function(attr, isActive) {
      var pointSet = this.get('pointSet');
      var areaSet = this.get('areaSet');
      pointSet.filterPoints(this.get('col'), attr, isActive);
      areaSet.queryPoints();
    },

    selectNone: function() {
      var pointSet = this.get('pointSet');
      pointSet.selectNoneAttr();
    },

    updateLegend: function() {
      this.get('areaSet').queryPoints();
    }

  });
}());
