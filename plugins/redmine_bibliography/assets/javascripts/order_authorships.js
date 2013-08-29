$(document).ready(function(){

   $('#authorships').sortable({
       axis: 'y',
       dropOnEmpty: false,
       handle: '.handle',
       cursor: 'crosshair',
       items: 'li',
       opacity: 0.4,
       scroll: true,
       update: function(){
          $.ajax({
              type: 'post',
              data: $('#authorships').sortable('serialize'),
              dataType: 'script',
              complete: function(request){
                 $('#authorship').effect('highlight');
              },
                 url: '/authorships/sort'});
              }
          });
     });






