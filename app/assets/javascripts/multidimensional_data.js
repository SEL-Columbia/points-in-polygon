$(document).ready(function(){
  function removeAllPoints(selected){
    for(var i=0;i<allPointsExisted.length;i++){
      pointsSelected = [];
    }
    for(var i=0;i<pointsOnMap.length;i++){
      if(pointsOnMap[i]['point']){
        colsLayer[selected].removeLayer(pointsOnMap[i]['point'][selected]);
      }
    }
    $('.legend-info').remove();
    areasLayer.eachLayer(function(l){
      var newStyle = null;
      newStyle = style(0, [[1, 1]]);
      l.setStyle(newStyle);
      l.originStyle = newStyle;
      l._options = newStyle;
    });
  }

  function showAllPoints(selected) {
    //levelInfo['clicked_areas'].push(levelInfo['area_id']);
    $(pointsOnMap).each(function(index){
      if(pointsOnMap[index]['point'] && pointsOnMap[index]['point'][selected]){
        colsLayer[selected].removeLayer(pointsOnMap[index]['point'][selected]);
        pointsOnMap[index]['point'][selected].addTo(colsLayer[selected])
      }
    });
    pointsSelected = allPointsExisted.slice();
  }

  bindSelectAll = function (selected) {
    $('.select-all').change(function(){
      if($('.select-all:checked').val() == '1'){
        showAllPoints(selected);
        $('.attrs-panel li').each(function(i){
          $(this).addClass('active');
        });
      } else {
        removeAllPoints(selected);
        $('.attrs-panel li').each(function(i){
          $(this).removeClass('active');
        });
      }
      makeUpdateLegend(selected);
    });
  }

  updatePointsBasedOnSelected = function(selected) {
    var activeList = $('.attrs-panel li.active');
    if(!selected) {
      return;
    }
    var attrs = [];
    for(var i=0;i<activeList.length;i++) {
      attrs.push($(activeList[i]).data('item'));
    }
    for(var i=0;i<pointsSelected.length;i++) {
      if($.inArray(pointsSelected[i][selected], attrs) < 0){
        pointsSelected.splice(i, 1);
      }
    }
    for(var i=0;i<pointsOnMap.length;i++){
      if($.inArray(pointsOnMap[i][selected], attrs) < 0){
        colsLayer[selected].removeLayer(pointsOnMap[i]['point'][selected]);
      }
    }
  }

  bindAttrLiClick = function (selected) {
    $('.attrs-panel li').click(function(e){

      attrLiClickSpinner = addSpin();
      // Remove all the points when click the panel first time
      if($('.attrs-panel li.active').length == 0) {
        removeAllPoints(selected);
      }
      $(this).toggleClass('active');
      var attr = $(this).data('item');
      var newPoints = [];
      // Delete points which are not selected
      if ($(this).hasClass('active')) {
        // Add the active points and remove the not ones
        for(var i=0;i<allPointsExisted.length;i++){
          if(allPointsExisted[i][selected] == attr){
            pointsSelected.push(allPointsExisted[i]);
          }
        }
      } else {
        for(var j=0;j<pointsSelected.length;j++){
          if(pointsSelected[j][selected] != attr){
            newPoints.push(pointsSelected[j]);
          }
        }
        pointsSelected = newPoints.slice();
      }
      for(var i=0;i<pointsOnMap.length;i++){
        if(pointsOnMap[i]['point'] && pointsOnMap[i]['point'][selected] && pointsOnMap[i][selected] == attr){
          if($(this).hasClass('active')) {
            pointsOnMap[i]['point'][selected].addTo(colsLayer[selected]);
          } else {
            colsLayer[selected].removeLayer(pointsOnMap[i]['point'][selected]);
          }
        }
      }

      if($('.attrs-panel li.active').length != $('.attrs-panel li').length){
        if($('.attrs-panel li.active').length == 0) {
          $('input:radio[name="select-all"][value="2"]').prop('checked', true);
        } else {
          $('input:radio[name="select-all"]').prop('checked', false);
        }
      } else {
        $('input:radio[name="select-all"][value="1"]').prop('checked', true);
      }
      // Change the legend and the areas
      makeUpdateLegend(selected);
    });
  }

  addAttrPanel = function (selected) {
    $('.attrs-panel').remove();
    var attrsPanel = L.control({position: 'bottomleft'});
    var attrColors = {};
    attrsPanel.onAdd = function(map) {
      var attrs = [];
      var attrsCount = {};
      for(var i=0;i < allPointsExisted.length;i++) {
        attrs.push(allPointsExisted[i][selected]);
        if(!attrsCount[allPointsExisted[i][selected]]) {
          attrsCount[allPointsExisted[i][selected]] = 0;
        }
        attrsCount[allPointsExisted[i][selected]] += 1;
      }
      attrs = attrs.unique();
      var totalCount = 0;
      for(var i=0;i<attrs.length;i++){
        totalCount += attrsCount[attrs[i]];
      }

      var table = L.DomUtil.create('ul', 'info attrs-panel');
      table.innerHTML += '<label><input type="radio" name="select-all" class="select-all" value="1"><span> Select All</span></label>' +
                         '<label><input type="radio" name="select-all" class="select-all" value="2"><span> Select None</span></label>';
      for(var i=0;i < attrs.length;i++) {
        table.innerHTML +=
          '<li data-item="' + attrs[i] + '">' +
          '<i style="background:' + colColors[selected][attrs[i]] + '"></i>' +
          '<span class="filter-label" title="'+attrs[i]+'">' + attrs[i] + '</span>' +
          '<span class="filter-count">' + attrsCount[attrs[i]] + '</span>' +
          //'<span>' + Math.floor(attrsCount[attrs[i]] / totalCount * 100) + '%</span>'
          '</li>';
      }

      return table;
    }
    attrsPanel.addTo(map);
  }

  selectAttr = function(m){
    var selected = this.colName;
    //if(m.hasLayer(pointsLayer)){
    this._map = m;
    this.eachLayer(m.addLayer, m);
    //}
    if(pointsLayer && !m.hasLayer(pointsLayer)){
      this.eachLayer(m.removeLayer, m);
      this._map = null;
    }
    
    addAttrPanel(selected);

    $('input:radio[name="select-all"][value="1"]').prop('checked', true);
    $('.attrs-panel li').each(function(i){
      $(this).addClass('active');
    });
    if(!m.hasLayer(pointsLayer)) {
      $('.attrs-panel').hide();
    } else {
      (pointsLayer).eachLayer(m.removeLayer, m);
      (pointsLayer)._map = null;
      showAllPoints(selected);
      //makeUpdateLegend(selected);
    }

    bindSelectAll(selected);
    bindAttrLiClick(selected);
    
    makeUpdateLegend(selected);

  };
  makeUpdateLegend = function(selected){
    var points = [];
    var activeAttrs = [];
    var listsActive = $('.attrs-panel li.active');
    for(var i=0;i<listsActive.length;i++){
      activeAttrs.push($(listsActive[i]).data('item').toString());
    }
    // Get all the points
    for(var i=0;i<allPointsExisted.length;i++){
      if(allPointsExisted[i]['point'] && allPointsExisted[i]['point'][selected] && allPointsExisted[i]['point'][selected].getLatLng()) {
        point = [allPointsExisted[i]['point'][selected].getLatLng().lat, allPointsExisted[i]['point'][selected].getLatLng().lng];
        if ($.inArray(allPointsExisted[i][selected], activeAttrs) >= 0) {
          points.push(point);
        }
      }
    }
    // Ajax to get tha data
    $.post('/layers/points_count', {layer_id: layer_id, points: points},
      function(data){
        var pointsInArea = data['points_in_area'];
        var pointsCountArr = data['points_count_arr'];
        var pointsAreaId = data['areas_id'];
        var countIdHash = data['count_id_hash']
        var colorGroup = getColorGroup(pointsCountArr);
        if(pointsInArea.length > 0) {
          addLegend(map, colorGroup);
        } else {
          $('.legend-info').remove();
        }
        for(k in areaTiles) {
          if(areaTiles.hasOwnProperty(k)) {
            tile = areaTiles[k];
            k = parseInt(k);
            if($.inArray(k, pointsAreaId) >= 0) {
              tile.setStyle(style(countIdHash[k], colorGroup));
            }  else {
              tile.setStyle(style(0, [[1, 1]]));
            }
          }
        }
      }
    );
  }
});
