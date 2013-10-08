// bibliography.js

function disable_fields(){
	$this = $(this);

	$author_info = $this.closest('div').prev();
//    $author_info.children('.description').toggle();
	$author_info.find('p :input').attr("readonly", true);
    $author_info.find('p :input').addClass('readonly');

    // Always hides on save
    $this.closest('div').prev().find('p.search_author_tie').hide();

    $this.siblings('.author_edit_btn').show();
    $this.hide();

    return false;
}

function enable_fields(){
    $this = $(this);

    $author_info = $this.closest('div').prev();
//    $author_info.children('.description').toggle();
    $author_info.find('p :input').attr("readonly", false);
    $author_info.find('p :input').removeClass('readonly');

    // Always shows on edit
    $this.closest('div').prev().find('p.search_author_tie').show();

    $this.siblings('.author_save_btn').show();
    $this.hide();

    return false;
}

