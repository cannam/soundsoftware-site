function toggleFieldsetWithState(this_field){
	id = Element.up(this_field, 'fieldset').id;

    // is the fieldset collapsed?
	var status = $(id).hasClassName("collapsed");
	change_session(id, status);

	toggleFieldset(this_field);
}

	function submitForm(){
		$('submitButton').click();
	}

function change_session(id, nstatus) {
	var url = "projects/set_fieldset_status";
    var request = new Ajax.Request(url, {
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

$(document).ready(function(){
	$('search-input').on('keypress', keypressHandler);
});