function toggle_ext_url() {
    if (document.getElementById('repository_is_external').checked) {
        document.getElementById('repository_external_url').disabled = false;
    } else {
	document.getElementById('repository_external_url').disabled = true;
    }
}

