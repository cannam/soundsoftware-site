// bibliography.js

function disable_fields(){
	$this = $(this);
	$author_info = $this.closest('div').prev();
	$author_info.children('.description').toggle();
	$author_info.find('p :input').attr("readonly", true);

    return false;
}