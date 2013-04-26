var app = app || {};

jQuery(function($){
  var Style = Backbone.Model.extend({
    defaults: {
      'colorsOfAreas': ['#FFEDA0', '#FED976', '#FEB24C', '#FD8D3C', '#FC4E2A', '#E31A1C', '#BD0026', '#800026'],
      'colorOfBlank': "#FFEFD0",
      'highlight': {
        weight: 4,
        color: '#666',
        dashArray: '',
        fillOpacity: 0.7
      },
      prettyColors: ["#DE1841", "#5DD517", "#1680CA", "#6016CA", "#FF1CF6", "#FF8B1C", "#EBFF1C", "#1CA4FF", "#F44747", "#9BDC00", "#E747C5", "#1C1841", "#462E46", "#61605B"]
    },
    // input: [3,1,5,6..9] array of counts in all areas
    getColorGrade: function(counts) {
      if(counts == []) return [[0, 0]];
      counts = _.sortBy(_.uniq(counts), function(n){
        return parseInt(n, 10);
      });
      var grades = [], groupCount = 5, count = counts.length;

      var i = 0;
      // counts is too few
      if(count <= 5) {
        for(i=0;i<count;i++) {
          grades.push([counts[i], counts[i]]);
        }
      } else {
        // first grade
        grades.push([counts[0], counts[0]]);
        // get the count of grades based on the count
        countGroup = getCountOfGrades(count);
        gradient = (counts[count - 2] - counts[1]) / (groupCount - 2);

        for(i=1;i<count - 1;) {
          var beginBorder = counts[i], endBorder = counts[i], j = 1;
          for(j=1;j<count-1-i;j++) {
            if(counts[i+j] - counts[i] <= gradient) {
              endBorder = counts[i + j];
            } else {
              break;
            }
          }
          i += j;
          grades.push([beginBorder, endBorder]);
        }
        // Keep the max value as the last grade
        grades.push([counts[count - 1], counts[count - 1]]);
      }
      if(grades.length < 1) {
        grades = [[0, 0]];
      }
      return grades;
    },

    getColor: function(count, grades) {
      if(count < grades[0][0] || typeof count === 'undefined') {
        return this.get('colorOfBlank');
      }
      for(var i=0;i < grades.length;i++) {
        if(count >= grades[i][0] && count <= grades[i][1]) {
          return this.get('colorsOfAreas')[i];
        }
      }
    },

    getStyle: function(count, grades) {
      return pathStyle(this.getColor(count, grades));
    },

    getPercentageStyle: function(p) {
      var index = getIndexByPercentage(p);
      return pathStyle(this.get('colorsOfAreas')[index]);
    },

    getPrettyColor: function(index) {
      var prettyColors = this.get('prettyColors');
      return prettyColors[index % prettyColors.length];
    },

    getBlankStyle: function() {
      return pathStyle(this.get('colorOfBlank'));
    }

  });

  // called by getColorGrade of Style class
  function getCountOfGrades(c) {
    return c > 64 ? 8 :
           c > 49 ? 7 :
           c > 36 ? 6 :
           5 ;
  }

  function getIndexByPercentage(p) {
    return p <= 13 ? 0:
           p <= 25 ? 1:
           p <= 38 ? 2:
           p <= 50 ? 3:
           p <= 63 ? 4:
           p <= 75 ? 5:
           p <= 88 ? 6:
           p <= 100 ? 7: 0;
  }

  function pathStyle(fillColor) {
    return {
      fillColor: fillColor,
      weight: 2,
      opacity: 1,
      color: 'white',
      dashArray: '3',
      fillOpacity: 0.7
    };
  }

  app.style = new Style();

});
