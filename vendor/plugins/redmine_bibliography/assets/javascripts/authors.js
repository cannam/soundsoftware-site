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

function update_author_info(form_object_id){
	$author = $('publication_authorships_attributes_' + form_object_id + '_search_results').value;
	
	alert($author.split('_')[0] + "  " + $author.split('_')[1]);
	
	alert("<%= " + $author.split('_')[0] + ".find(" + $author.split('_')[1] + ").name %>")
	
	$('publication_authorships_attributes_' + form_object_id + '_name_on_paper').value = $author
			
	//$(link).up('div').up('div').select('input[id^=publication_authorships_attributes]').each(
	//	function(e){
	//		key = e.name.split("[").last().trim().sub(']','');
	//		
	//		// test for undefined			
	//		e.value = author_info[key];
	//	}		
	//)
}