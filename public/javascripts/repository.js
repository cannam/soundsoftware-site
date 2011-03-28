function toggle_ext_url(){
	if($('repository_is_external').checked)
	    $('repository_external_url').enable();
	else
	    $('repository_external_url').disable();
}

