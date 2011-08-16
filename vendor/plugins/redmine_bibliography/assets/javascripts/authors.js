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
			name_field.disabled = true;
			email_field.disabled = true;
			institution_field.disabled = true;
		break;
		case "no":
			name_field.value = "";
			email_field.value = "";
			institution_field.value = "";
		
			name_field.disabled = false;
			email_field.disabled = false;
			institution_field.disabled = false;

		break;
		case "correct":
			name_field.disabled = false;
			email_field.disabled = false;
			institution_field.disabled = false;
		break;
	}
}
