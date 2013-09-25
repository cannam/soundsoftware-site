// edit_publication.js

$(document).ready(function(){
    // shows the correct bibtex fields
    $('#publication_bibtex_entry_attributes_entry_type').trigger('change');

    // adds the events to the edit/save authorship button
    $('.author_save_btn').live('click', disable_fields);
    $('.author_edit_btn').live('click', enable_fields);

    // clicks all authorships
    $('.author_save_btn').trigger('click');
});