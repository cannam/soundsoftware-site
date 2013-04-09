

/* SSAMR specific functions */

/* institution related functions */
$(document).ready(function(){
	$('#ssamr_user_details_institution_type_true').click(function() {
        $('#ssamr_user_details_other_institution').attr('disabled', 'disabled');
        $('#ssamr_user_details_institution_id').removeAttr('disabled');
	});

	$('#ssamr_user_details_institution_type_false').click(function() {
        $('#ssamr_user_details_other_institution').removeAttr('disabled');
        $('#ssamr_user_details_institution_id').attr('disabled', 'disabled');
	});

    if($('#ssamr_user_details_institution_type_true').checked)
        $('#ssamr_user_details_other_institution').attr('disabled', 'disabled');
    else if($('ssamr_user_details_institution_type_false').checked)
        $('#ssamr_user_details_institution_id').attr('disabled', 'disabled');
	else {
		$('#ssamr_user_details_other_institution').attr('disabled', 'disabled');
        $('#ssamr_user_details_institution_id').removeAttr('disabled');
        $('#ssamr_user_details_institution_type_true').checked = true;
        $('#ssamr_user_details_institution_type_false').checked = false;
	}
}
);



