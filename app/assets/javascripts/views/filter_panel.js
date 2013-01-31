var app = app || {};

jQuery(function($){
  app.FilterPanelView = Backbone.View.extend({
    initialize: function() {
      var panel = L.control({position: 'bottomleft'});
      panel.onAdd = function(map) {
        return L.DomUtil.create('DIV', 'info attrs-panel');
      };
      panel.addTo(this.options.map);
      this.lPanel = panel;

      $('.attrs-panel').hide();

      //this.listenTo(this.model, "change", this.render);

      // bind some custom events, use ON!
      this.on('noneCol', this.hide);
      this.on('switchCol', this.show);
      this.on('click', this.click);

      var that = this;
      $('.attrs-panel tr.filter').live('click', function(){
        $(this).toggleClass('active');
        that.clicked = this;
        that.trigger('click');
      });

      $('.attrs-panel .all').live('click', function() {
        that.selectAll();
      });

      $('.attrs-panel .none').live('click', function() {
        that.selectNone();
      });
    },

    renderPanel: function(entries) {
      var panel = JST['templates/filter_panel']({entries: entries});
      $('.attrs-panel').html(panel).show();
    },

    show: function(col, entries) {
      this.renderPanel(entries);
      _.each($('.attrs-panel tr.filter'), function(tr){
        $(tr).addClass('active');
      });
      $('.attrs-panel input:radio[name="select-all"][value="1"]').prop('checked', true);

      this.col = col;
    },

    hide: function() {
      $('.attrs-panel').hide();
    },

    click: function() {
      app.loading.start();
      var clickedRow = this.clicked;
      var attr = $(clickedRow).data('name');
      var isActive = $(clickedRow).hasClass('active');

      this.model.filterPoints(attr, isActive);
      this.adjustSelectRadio();
      app.loading.stop();
    },

    adjustSelectRadio: function() {
      var $panel = $('.attrs-panel tr.filter');
      var $activedPanel = $('.attrs-panel tr.filter.active');
      if($activedPanel.length != $panel.length) {
        if($activedPanel.length === 0) {
          $('.attrs-panel input:radio[name="select-all"][value="2"]').prop('checked', true);
        } else {
          $('.attrs-panel input:radio[name="select-all"]').prop('checked', false);
        }
      } else {
        $('input:radio[name="select-all"][value="1"]').prop('checked', true);
      }
    },

    selectAll: function() {
      this.model.get('pointSet').showAll();
      this.model.accessCount(this.col);
      //this.show(this.col);
    },

    selectNone: function() {
      $('.attrs-panel tr.filter').each(function(i){
        $(this).removeClass('active');
      });
      this.model.selectNone();
      this.model.updateLegend();
    },

    goback: function() {
      this.hide();
    }
  });
});
