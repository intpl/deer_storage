window.addEventListener('load', function() {
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
});
