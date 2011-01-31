

/* SSAMR specific functions */

/* institution related functions */
Event.observe(window, 'load',
  function() {
	$('ssamr_user_details_institution_type_true').observe('click', function(e, el) {
	    $('ssamr_user_details_other_institution').disable();
		$('ssamr_user_details_institution_id').enable();
	});

	$('ssamr_user_details_institution_type_false').observe('click', function(e, el) {
	    $('ssamr_user_details_other_institution').enable();
		$('ssamr_user_details_institution_id').disable();
	});
        
    if($('ssamr_user_details_institution_type_true').checked)
        $('ssamr_user_details_other_institution').disable();
    else if($('ssamr_user_details_institution_type_false').checked)
        $('ssamr_user_details_institution_id').disable();
}
);



