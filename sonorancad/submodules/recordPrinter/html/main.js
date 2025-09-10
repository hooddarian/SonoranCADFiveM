var image_link;
var first = null;
$(function () {
  window.onload = (e) => {
    window.addEventListener('message', function (event) {
      if (event.data.length > 4 || event.data.length <= 10) {
        length = event.data.length;
      }
      if (event.data.link != null) image_link = event.data.link;
      if (event.data.first != null) first = event.data.first;
      show = event.data.show;
      switch (event.data.action) {
        case 'openui':
          this.document.getElementById('p1').src = event.data.link;
          $('body').fadeIn();
          break;
        case 'closeui':
          $('body').fadeOut();
          this.document.getElementById('p1').src = '';
          $.post(
            'https://sonorancad/CloseUI',
            JSON.stringify({ link: image_link, first: first })
          );
          break;
        default:
          break;
      }
    });
  };
  document.onkeyup = function (event) {
    if (event.key == 'Escape') {
      $('body').fadeOut();
      $.post(
        'https://sonorancad/CloseUI',
        JSON.stringify({ link: image_link, first: first })
      );
    }
  };
});
