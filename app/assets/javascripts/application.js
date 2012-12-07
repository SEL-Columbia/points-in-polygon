// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require leaflet
//= require_tree .
$(document).ready(function() {
  $("a.query-layer").click(function(){
    var layer_id = $(this).data('layer-id');
    var query_url = "/layers/" + layer_id + "/points/";
    var query_params = $("#points_for_layer_" + layer_id).val();
    window.location = query_url + query_params;
  });
});

function getColor(d) {
  return d > 128 ? '#800026' :
         d > 64  ? '#BD0026' :
         d > 32  ? '#E31A1C' :
         d > 16  ? '#FC4E2A' :
         d > 8   ? '#FD8D3C' :
         d > 4   ? '#FEB24C' :
         d > 2   ? '#FED976' :
                    '#FFEDA0';
}

function polygonStyle(d){
  return {
      fillColor: getColor(d),
      weight: 2,
      opacity: 1,
      color: 'white',
      dashArray: '3',
      fillOpacity: 0.7
  };
}

function style(d) {
  return d > 0 ? polygonStyle(d) : {};
}
