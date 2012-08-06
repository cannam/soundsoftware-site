function remove_fields(link) {
    $(link).previous("input[type=hidden]").value = "1";
    $(link).up(".fields").hide();
}

function add_author_fields(link, association, content, action) {
	var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");

  $('authors').insert(content.replace(regexp, new_id));

	if(action != "new"){
		toggle_save_author(new_id, $(link));
	};
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
    if (field.classNames().inspect().include("readonly") == false){
			field.readOnly = true;	
			field.addClassName('readonly');
    } else {
			field.readOnly = false;
			field.removeClassName('readonly');
    };	
}

function toggle_edit_save_button(object_id){
    $button = $('publication_authorships_attributes_' + object_id + '_edit_save_button');
    if ($button.value == "Edit author"){
	$button.value = "Save author";
    } else {
	$button.value = "Edit author";
    };
}

function toggle_save_author(form_object_id, $this){
    $('publication_authorships_attributes_' + form_object_id + '_edit_author_info').select('input').each(function(s) {
	toggle_input_field(s, $this);
    });
    $('publication_authorships_attributes_' + form_object_id + '_edit_author_info').select('p.description').each(function(s) {
	s.toggle();
    });
    toggle_edit_save_button(form_object_id);
    toggle_div("publication_authorships_attributes_" + form_object_id +"_search_author");
}

function hide_all_bibtex_required_fields(){$$('p.bibtex').each(function(s){s.hide()})}

// entrytype_fields is a jsno array with the fields requires by the selected bibtex entry 
function show_required_bibtex_fields(entrytype_fields) {
	$$('p.bibtex').each(function(s){
		if(entrytype_fields.indexOf(s.down('input').id.split('_').last()) != -1){
			s.show();
			}
		else {
			s.hide();
			}
	})
}
		