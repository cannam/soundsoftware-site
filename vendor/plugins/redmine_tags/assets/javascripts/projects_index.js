function toggleFieldsetWithState(this_field){
	id = Element.up(this_field, 'fieldset').id;	
	// is the fieldset collapsed?
	status = $(id).hasClassName("collapsed");
	change_session(id, status);
	
	toggleFieldset(this_field);
};

function change_session(id, nstatus) {
	var url = "projects/set_fieldset_status";
 	var request = new Ajax.Request(url, {
		method: 'post',
	 	parameters: {field_id: id, status: nstatus},
    	asynchronous: true
  	});
}

function submitForm(){
	$('submitButton').click(); return false;
}