function add_author_fields(link, association, content, action) {
    var new_id = new Date().getTime();
    var regexp = new RegExp("new_" + association, "g");

    $(link).before(content.replace(regexp, new_id));

    if(action != "new"){
        toggle_save_author(new_id, $(link));
    }
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
            $this.closest('div').next().find("input[id$='name_on_paper']").val(ui.item.name);
            $this.closest('div').next().find("input[id$='institution']").val(ui.item.institution);
            $this.closest('div').next().find("input[id$='email']").val(ui.item.email);
            $this.closest('div').next().find("input[id$='search_author_class']").val(ui.item.search_author_class);
            $this.closest('div').next().find("input[id$='search_author_id']").val(ui.item.search_author_id);

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
            return $( "<li></li>" )
                .data( "item.autocomplete", item )
                .append( "<a>" + item.label + "</a>" )
                .appendTo( ul );
            };
        });

function toggle_div(div_id){
    $("#" + div_id).toggle(0.3);
}

function toggle_save_author(form_object_id, $this){
    $('publication_authorships_attributes_' + form_object_id + '_edit_author_info').select('input').each(function(s) {
	toggle_input_field(s, $this);
    });
    $('publication_authorships_attributes_' + form_object_id + '_edit_author_info').select('p.description').each(function(s) {
	s.toggle();
    });
    toggle_edit_save_button(form_object_id);
    toggle_div("publication_authorships_attributes_" + form_object_id +"_search_author");
}