

/* SSAMR specific functions */

/* institution related functions */
Event.observe(window, 'load',
  function() {
	
  $('ssamr_user_details_other_institution').disable();
  $('ssamr_user_details_institution_id').enable();
  $('ssamr_user_details_institution_type_true').checked = true;
  $('ssamr_user_details_institution_type_false').checked = false;
}
);



