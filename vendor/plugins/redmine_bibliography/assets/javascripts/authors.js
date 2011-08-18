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
	$('publication_authorships_attributes_' + object_id + '_edit_author_info').select('input').each(function(s) {
		if(status == "no"){
			s.value = "";
			s.readOnly = false;
		};
		
		if(status == "correct"){s.readOnly = false;};
		if(status == "yes"){s.readOnly = true;};
	});
}

function toggle_div(div_id){	
	Effect.toggle(div_id, "appear", {duration:0.3});
}

function toggle_input_field(field){	
	if(field.readOnly == false){
		field.readOnly = true;	
		field.addClassName('readonly').next('em').hide();
	} else{
		field.readOnly = false;
		field.removeClassName('readonly').next('em').show();		
	};	
}

function toggle_edit_save_button(object_id){
	$button = $('publication_authorships_attributes_' + object_id + '_edit_save_button');
	if($button.value == "Save Author"){
		$button.value = "Edit Author";	
	} else {
		$button.value = "Save Author";
	};
}

function toggle_save_author(form_object_id, $this){
	$('publication_authorships_attributes_' + form_object_id + '_edit_author_info').select('input').each(function(s) {
	  toggle_input_field(s, $this);
	});
	
	toggle_edit_save_button(form_object_id);
	toggle_div("publication_authorships_attributes_" + form_object_id +"_search_author");
}

function edit_author(form_object_id){
	
	
}

