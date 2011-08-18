function remove_fields(link) {
  $(link).previous("input[type=hidden]").value = "1";
  $(link).up(".fields").hide();
}

function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g")
  $(link).insert({
    before: content.replace(regexp, new_id)
  });
}

function identify_author_status(status, object_id) {
	name_field = $('publication_authorships_attributes_' + object_id + '_name_on_paper');
    email_field = $('publication_authorships_attributes_' + object_id + '_email');
    institution_field = $('publication_authorships_attributes_' + object_id + '_institution');

	switch(status)
	{
		case "yes":
			name_field.readOnly = true;
			email_field.readOnly = true;
			institution_field.readOnly = true;
		break;
		case "no":
			name_field.value = "";
			email_field.value = "";
			institution_field.value = "";
		
			name_field.readOnly = false;
			email_field.readOnly = false;
			institution_field.readOnly = false;

		break;
		case "correct":
			name_field.readOnly = false;
			email_field.readOnly = false;
			institution_field.readOnly = false;
		break;
	}
}

function toggle_div(div_id){	
	Effect.toggle(div_id, "appear", {duration:0.3});
}

function toggle_input_field(field_id){
	$(field_id).addClassName('readonly');
	$(field_id).next('em').hide();
}

function toggle_save_author(form_object_id){
	toggle_input_field("publication_authorships_attributes_" + form_object_id + "_name_on_paper");
	toggle_input_field("publication_authorships_attributes_" + form_object_id + "_institution");
	toggle_input_field("publication_authorships_attributes_" + form_object_id + "_email");

	toggle_div("publication_authorships_attributes_" + form_object_id +"_search_author");
}

function edit_author(form_object_id){
	
	
}

