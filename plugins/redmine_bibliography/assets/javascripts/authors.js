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
        select: function(event, ui){
            $this.closest('div').next().find("input[id$='name_on_paper']").val(ui.item.value);
            $this.closest('div').next().find("input[id$='institution']").val(ui.item.institution);
            $this.closest('div').next().find("input[id$='email']").val(ui.item.email);
            $this.closest('div').next().find("input[id$='object_class']").val(ui.item.object_class);
        }
    });
});




function identify_author_status(status, object_id) {
    $('publication_authorships_attributes_' + object_id + '_edit_author_info').select('input').each(function(s) {

        if(status == "no"){
            s.value = "";
            s.readOnly = false;
        }

        if(status == "correct"){
            s.readOnly = false;
        }
        if(status == "yes"){
            s.readOnly = true;
        }
    });
}

function toggle_div(div_id){
    $("#" + div_id).toggle(0.3);
}

function toggle_input_field(field){
    if (field.classNames().inspect().include("readonly") === false){
			field.readOnly = true;
			field.addClassName('readonly');
    } else {
			field.readOnly = false;
			field.removeClassName('readonly');
    }
}

function toggle_edit_save_button(object_id){
    $button = $('publication_authorships_attributes_' + object_id + '_edit_save_button');
    if ($button.value == "Edit author"){
	$button.value = "Save author";
    } else {
	$button.value = "Edit author";
    };
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