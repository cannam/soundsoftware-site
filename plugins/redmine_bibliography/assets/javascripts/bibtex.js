function toggleBibtex(el) {
  var dd = Element.up(el).next('dd');

  dd.toggleClassName('collapsed');
  Effect.toggle(dd, 'slide', {duration:0.2});
}