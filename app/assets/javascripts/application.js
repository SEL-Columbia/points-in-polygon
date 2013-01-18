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
//= require sugar-1.3.7.min
//= require leaflet.markercluster
//= require spin.min
//= require_tree .
$(document).ready(function() {
  $("a.query-layer").click(function(){
    var layer_id = $(this).data('layer-id');
    var format = $(this).data('format');
    format = format ? format : '';
    var query_url = "/layers/" + layer_id + "/points/";
    var query_params = $("#points_for_layer_" + layer_id).val();
    window.location = query_url + query_params + format;
  });

});

function getColor(count, colorGroup) {
  if(count < colorGroup[0][0]) return "#FFEFD0";
  for(var i=0;i < colorGroup.length;i++) {
    if(count >= colorGroup[i][0] && count <= colorGroup[i][1]) {
      return ['#FFEDA0', '#FED976', '#FEB24C', '#FD8D3C', '#FC4E2A', '#E31A1C', '#BD0026', '#800026'][i];
    }
  }
}

function polygonStyle(count, colorGroup){
  return {
      fillColor: getColor(count, colorGroup),
      weight: 2,
      opacity: 1,
      color: 'white',
      dashArray: '3',
      fillOpacity: 0.7
  };
}

function style(count, colorGroup) {
  return count >= -1 ? polygonStyle(count, colorGroup) : {};
}

//Array.prototype.unique = function() {
//  var o = {}, i, l = this.length, r = [];
//  for(i=0; i<l;i+=1) o[this[i]] = this[i];
//  for(i in o) r.push(o[i]);
//  return r;
//};

