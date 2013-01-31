var app = app || {};

jQuery(function($){
  // Legend
  // grades, app.style, areaSet
  app.Legend = Backbone.Model.extend({
    // {area_id: count, ... }
    update: function(data) {
      var counts = data.counts;
      var countArr = _.values(counts);
      var areaIds = _.keys(counts);

      var style = this.get('style');
      var grades = style.getColorGrade(countArr);
      this.set('grades', grades);

      this.get('areaSet').each(function(area){
        var count = counts[area.get('areaId')];
        if(_.indexOf(areaIds, area.get('areaId')) >= 0) {
          if(area.get('showWay') == 'percentage') {
            var percent = parseInt(count / area.get('totalCount') * 100, 10);
            app.style.getPercentageStyle(percent);
            area.setStyle(app.style.getPercentageStyle(percent));
          } else {
            area.setStyle(style.getStyle(count, grades));
          }
          area.set('magnitudeStyle', style.getStyle(count, grades));
          area.set('count', (count));
        } else {
          area.set('magnitudeStyle', style.getBlankStyle());
          area.setStyle(style.getBlankStyle());
          area.set('count', count);
        }
      });
    }
  });
});
