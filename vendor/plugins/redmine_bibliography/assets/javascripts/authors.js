function remove_author(link){
	$(link).previous("input[type=hidden]").value = 1;
	$(link).up(".author_fields").hide();
}