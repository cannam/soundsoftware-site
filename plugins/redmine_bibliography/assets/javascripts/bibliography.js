$("#publication_bibtex_entry_attributes_entry_type").live("change", function() {
    $.ajax({
        type: "POST",
        url: "/publications/show_bibtex_fields",
        data: "value=" + $("#publication_bibtex_entry_attributes_entry_type").val(),
        dataType: "script"
    });

    return false;
});

