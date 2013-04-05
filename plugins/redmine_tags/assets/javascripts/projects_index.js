var IndexFilter = {
    init: function(){
        var self = this;
        $('fieldset#filters_fieldset legend').live("click", self.toggle);
        // $('fieldset #submitButton').live("click", self.submitSearch);
    },

    expanded: false,

    toggle: function(){
        var fieldset = $(this).parents('fieldset').first();
        fieldset.toggleClass('collapsed');
        fieldset.children('div').toggle();
    },
    submitSearch: function(){
        console.log("Submitting search");
        $(this).submit();
        return false;
    }
};





/*
    function toggleFieldsetWithState(obj){
        var fset = $(obj).parent('fieldset');

        // is the fieldset collapsed?
	var status = fset.hasClass("collapsed");

        // change_session(fset, status);
	// toggleFieldset(fset);
    }




    function change_session(id, nstatus) {
	var url = "projects/set_fieldset_status";
    var request = new jQuery.ajax(url, {
	method: 'post',
          parameters: {field_id: id, status: nstatus},
          asynchronous: true
        });
    }


function keypressHandler (event){
  var key = event.which || event.keyCode;
  switch (key) {
      default:
        break;
      case Event.KEY_RETURN:
          $('submitButton').click();
          return false;
  }
}

*/

$(document).ready(function(){
//	$('search-input').on('keypress', keypressHandler);
    IndexFilter.init();
});