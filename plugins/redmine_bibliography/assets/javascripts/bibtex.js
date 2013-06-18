
$('.bibtex-link').live("click", function() {
  $this = $(this);
  $this.closest('dd').next('dd').toggle();
});