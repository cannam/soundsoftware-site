
$("#publication_bibtex_entry_attributes_entry_type").live("change", function() {
    $this = $(this);

    $.ajax({
        type: "get",
        url: "/publications/show_bibtex_fields",
        data: {
            value: $this.val()
        },
        dataType: "script"
    });

    return false;
});
