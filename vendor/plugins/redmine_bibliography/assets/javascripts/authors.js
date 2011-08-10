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

function update_author_info(link, author_info){
		
	$(link).up('div').up('div').select('input[id^=publication_authorships_attributes]').each(
		function(e){
			key = e.name.split("[").last().trim().sub(']','');
			
			// test for undefined			
			e.value = author_info[key];
		}		
	)
}