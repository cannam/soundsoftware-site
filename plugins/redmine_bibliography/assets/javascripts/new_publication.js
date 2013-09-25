// edit_publication.js

$(document).ready(function(){
    // adds the events to the edit/save authorship button
    $('.author_save_btn').live('click', disable_fields);
    $('.author_edit_btn').live('click', enable_fields);
});