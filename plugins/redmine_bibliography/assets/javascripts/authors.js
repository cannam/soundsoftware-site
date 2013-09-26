function add_author_fields(link, association, content, action) {
    var new_id = new Date().getTime();
    var regexp = new RegExp("new_" + association, "g");

    $(link).before(content.replace(regexp, new_id));
}

function remove_fields(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".fields").hide();
}

$(".author_search").live('keyup.autocomplete', function(){
     $this = $(this);

     $this.autocomplete({
        source: '/publications/autocomplete_for_author',
        minLength: 2,
        focus: function(event, ui) {
            $this.val(ui.item.label);
            return false;
        },
        select: function(event, ui){
            $this.closest('div').next().find("input[id$='name_on_paper']").val(ui.item.name);
            $this.closest('div').next().find("input[id$='institution']").val(ui.item.institution);
            $this.closest('div').next().find("input[id$='email']").val(ui.item.email);
            $this.closest('div').next().find("input[id$='search_author_class']").val(ui.item.search_author_class);
            $this.closest('div').next().find("input[id$='search_author_id']").val(ui.item.search_author_id);
        }
        })
        .data( "autocomplete" )._renderItem = function( ul, item ) {
            return $( "<li>" )
                .data("item.autocomplete", item )
                .append( "<a>" + item.label + "<br><em>" + item.email + "</em><br>" + item.intitution + "</a>" )
                .appendTo(ul);
            };
        });


$("input[id$='identify_author_yes']").live("click", function() {
    console.log("aaaa");
});

$("input[id$='identify_author_no']").live("click", function() {
    $this.closest('div').next().find("input[id$='name_on_paper']").val('');
    $this.closest('div').next().find("input[id$='institution']").val('');
    $this.closest('div').next().find("input[id$='email']").val('');
    $this.closest('div').next().find("input[id$='search_author_class']").val('');
});

