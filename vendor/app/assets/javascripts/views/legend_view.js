var app = app || {};

jQuery(function($){
  app.LegendView = Backbone.View.extend({

    className: "legend-info",

    initialize: function() {
      var legend = L.control({position: 'bottomright'});
      legend.onAdd = function(map) {
        return L.DomUtil.create('div', 'legend-info legend');
      };
      legend.addTo(this.options.map);
      this.lLegend = legend;

      this.listenTo(this.model, "change", this.render);

      this.showWay = "magnitude";

      var that = this;
      $('.legend-info .magnitude').live('click', function() {
        if(that.showWay != 'magnitude') {
          that.trigger('showWayChange', 'magnitude');
        }
        that.showWay = "magnitude";
        that.render();
      });
      $('.legend-info .percentage').live('click', function() {
        if(that.showWay != 'percentage') {
          that.trigger('showWayChange', 'percentage');
        }
        that.showWay = "percentage";
        that.render();
      });

    },

    hide: function() {
      $('.legend-info').hide();
    },

    show: function() {
      $('.legend-info').show();
    },

    reset: function() {
      $('.legend-info input:radio[name="switch-legend"][value="1"]').prop('checked', true);
      this.showWay = "percentage";
    },

    render: function() {
      var tmpl = "";
      var style = this.model.get('style');
      var colors = [];

      if (this.showWay == "magnitude") {
        var grades = this.model.get('grades');
        if(_.isEqual(grades, [[0, 0]])) {
          this.hide();

          return this;
        }

        _.each(grades, function(g) {
          colors.push(style.getColor(g[1], grades));
        });

        tmpl = JST['templates/legend'](
          {grades: grades, colors: colors}
        );
        $('.legend-info').html(tmpl);
        $('.legend-info input:radio[name="switch-legend"][value="1"]').prop('checked', true);
      } else if (this.showWay == "percentage") {
        colors = style.get('colorsOfAreas');
        tmpl = JST['templates/legend_percentage'](
          {percent: ["<13%", "<25%", "<38%", "<50%", "<63%", "<75%", "<88%", "<100%"], colors: colors}
        );
        $('.legend-info').html(tmpl);
        $('.legend-info input:radio[name="switch-legend"][value="2"]').prop('checked', true);
      }
      this.show();

      return this;
    }
  });
});
