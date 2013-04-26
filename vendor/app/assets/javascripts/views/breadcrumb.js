var app = app || {};

jQuery(function($){
  app.Breadcrumb = Backbone.View.extend({
    el: 'ul.breadcrumb',

    initialize: function() {
      this.$el.html("<li class='active' data-level='0'>Level 0</li>");
      this.level = 0;
      this.canExpand = true;
      this.record = {};
    },

    events: {
      "click a": "goback"
    },

    expand: function() {
      var oldStr = "<a href='#'>Level " + this.level + "</a> <span class='divider'>/</span>";
      this.level += 1;
      var newStr = "<li class='active' data-level='" + this.level + "'>Level " + this.level + "</li>";

      this.$el.children('.active').removeClass('active').html(oldStr);

      this.$el.append(newStr);

      var colsFeatureGroup = this.colsFeatureGroup;
      for( var k in colsFeatureGroup) {
        if(colsFeatureGroup.hasOwnProperty(k)) {
          app.map.get('lMap').removeLayer(colsFeatureGroup[k]);
        }
      }
    },

    recordClick: function(record) {
      this.record[this.level] = record;
    },

    goback: function(e) {
      app.loading.start();
      var target = e.target;
      $(target).parent().nextAll().remove();
      var level = $(target.parentNode).data('level');
      $(target).parent().remove();

      var grades = this.record[level].grades;

      this.pointSet.goback();

      this.areaSet.goback(level, this.record[level].layerId, grades);

      this.level = level;

      var newStr = "<li class='active' data-level='" + this.level + "'>Level " + this.level + "</li>";

      this.$el.append(newStr);

      this.filterPanelView.hide();
      $('.leaflet-control-layers-base input:checked').prop('checked', false);
      $('.leaflet-control-layers-base input:first').prop('checked', true);

      var colsFeatureGroup = this.colsFeatureGroup;
      for( var k in colsFeatureGroup) {
        if(colsFeatureGroup.hasOwnProperty(k)) {
          app.map.get('lMap').removeLayer(colsFeatureGroup[k]);
        }
      }
      app.loading.stop();
    }
  });
});
