window.hook_navbar_burger = function() {
  // Close mobile & tablet menu on item click
  $('.navbar-item').each(function(e) {
    $(this).click(function(){
      if($('.navbar-burger').hasClass('is-active')){
        $('.navbar-burger').removeClass('is-active');
        $('#navigation').removeClass('is-active');
      }
    });
  });

  // Open or Close mobile & tablet menu
  $('.navbar-burger').click(function () {
    if($('.navbar-burger').hasClass('is-active')){
      $('.navbar-burger').removeClass('is-active');
      $('#navigation').removeClass('is-active');
    }else {
      $('.navbar-burger').addClass('is-active');
      $('#navigation').addClass('is-active');
    }
  });
}

// exclude all paths that use liveview navigation, as phx-hooks take care of calling window.hook_navbar_burger
// FIXME: root path shows live navigation
if (!window.location.href.match('^(.*(records|dashboard|registration/edit|users|invitation)).*$')) {
  window.addEventListener('load', window.hook_navbar_burger);
}
