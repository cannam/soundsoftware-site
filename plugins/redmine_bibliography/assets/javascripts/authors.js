function add_author_fields(link, association, content, action) {
    var new_id = new Date().getTime();
    var regexp = new RegExp("new_" + association, "g");

    $(link).before(content.replace(regexp, new_id));
}

function remove_fields(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".fields").hide();
}

$(".author_name_on_paper").live('keyup.autocomplete', function(){
     $this = $(this);

     $this.autocomplete({
        source: '/publications/autocomplete_for_author',
        minLength: 2,
        focus: function(event, ui) {
            $this.val(ui.item.label);
            return false;
        },
        select: function(event, ui){
            $this.closest('div').find("input[id$='institution']").val(ui.item.institution);
            $this.closest('div').find("input[id$='email']").val(ui.item.email);

            $this.closest('div').find("input[id$='search_author_class']").val(ui.item.search_author_class);
            $this.closest('div').find("input[id$='search_author_id']").val(ui.item.search_author_id);

            $this.closest('div').find("input[id$='search_author_tie']").attr('checked', 'checked');
            $this.closest('div').find("input[id$='search_author_tie']").next('span').replaceWith(ui.item.authorship_link);

            // triggers the save button
            $this.closest('div').next('div').find('.author_save_btn').click();
        }
        })
        .data( "autocomplete" )._renderItem = function( ul, item ) {
            return $( "<li>" )
                .data("item.autocomplete", item )
                .append( "<a>" + item.label + "<br><em>" + item.email + "</em><br>" + item.institution + "</a>" )
                .appendTo(ul);
            };
        });

