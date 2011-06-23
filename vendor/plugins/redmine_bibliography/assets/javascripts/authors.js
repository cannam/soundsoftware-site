function remove_author(link){
	$(link).previous('input[type=hidden]').value = 1;
	$(link).up('.author_fields').remove();
}

function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g")
  $(link).parent().before(content.replace(regexp, new_id));
}