var app = app || {};
(function() {
  app.Loading = Backbone.View.extend({
    el: '#spinner',

    initialize: function() {
      this.opts = {
        lines: 11, // The number of lines to draw
        length: 6, // The length of each line
        width: 4, // The line thickness
        radius: 10, // The radius of the inner circle
        corners: 1, // Corner roundness (0..1)
        rotate: 0, // The rotation offset
        color: '#000', // #rgb or #rrggbb
        speed: 1, // Rounds per second
        trail: 60, // Afterglow percentage
        shadow: false, // Whether to render a shadow
        hwaccel: false, // Whether to use hardware acceleration
        className: 'spinner', // The CSS class to assign to the spinner
        zIndex: 2e9, // The z-index (defaults to 2000000000)
        top: 'auto', // Top position relative to parent in px
        left: 'auto' // Left position relative to parent in px
      };

      this.target = document.getElementById('spinner');
      this.counter = 0;
    },

    start: function() {
      this.counter += 1;
      if(this.counter === 1) {
        this.spinner = new Spinner(this.opts).spin(this.target);
      }
      $('#map').css({opacity: 0.5});
    },

    stop: function() {
      this.counter -= 1;
      if(this.counter <= 0 && this.spinner) {
        this.spinner.stop();
        $('#map').css({opacity: 1});
        this.counter = 0;
      }
    }
  });
}());
