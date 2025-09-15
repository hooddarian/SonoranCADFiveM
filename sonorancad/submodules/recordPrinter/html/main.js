var pdfLink = '';
var firstView = false;
var isOpen = false;
var isMinimized = false;
var isFullscreen = false;

$(function () {
  var $wrapper = $('#wrapper');
  var $pdfWindow = $('#pdfWindow');
  var $pdfFrame = $('#pdfFrame');
  var $statusText = $('#statusText');
  var $minimizeBtn = $('#minimizeBtn');
  var $fullscreenBtn = $('#fullscreenBtn');
  var $closeBtn = $('#closeBtn');

  function updateStatusText() {
    if (!isOpen) {
      $statusText.text('');
      return;
    }

    if (isMinimized) {
      $statusText.text('Press Backspace to restore.');
    } else if (isFullscreen) {
      $statusText.text('Scroll to view the record. Backspace to minimize, ESC to close.');
    } else {
      $statusText.text('Press Backspace to minimize, ESC to close.');
    }
  }

  function applyWindowState() {
    var shouldFullscreen = isFullscreen && !isMinimized;
    $pdfWindow.toggleClass('minimized', isMinimized);
    $pdfWindow.toggleClass('fullscreen', shouldFullscreen);

    $minimizeBtn.text(isMinimized ? 'Restore' : 'Min');
    $minimizeBtn.attr('title', isMinimized ? 'Restore' : 'Minimize');
    $fullscreenBtn.text(shouldFullscreen ? 'Exit Full' : 'Full');
    $fullscreenBtn.attr('title', shouldFullscreen ? 'Exit Fullscreen' : 'Toggle Fullscreen');

    updateStatusText();
  }

  function openUI(link, firstFlag) {
    if (link) {
      pdfLink = link;
      $pdfFrame.attr('src', link);
    }
    firstView = !!firstFlag;
    isOpen = true;
    isMinimized = false;
    isFullscreen = false;

    applyWindowState();

    $wrapper.removeClass('hidden');
    $wrapper.stop(true, true).fadeIn(120);
  }

  function closeUI(sendMessage) {
    if (!isOpen) {
      return;
    }

    isOpen = false;
    isMinimized = false;
    isFullscreen = false;

    $wrapper.stop(true, true).fadeOut(120, function () {
      $pdfFrame.attr('src', '');
      $wrapper.addClass('hidden');
      updateStatusText();
    });

    if (sendMessage !== false) {
      $.post('https://sonorancad/CloseUI', JSON.stringify({ link: pdfLink, first: firstView }));
    }
  }

  function toggleMinimize(force) {
    if (!isOpen) {
      return;
    }

    if (typeof force === 'boolean') {
      isMinimized = force;
    } else {
      isMinimized = !isMinimized;
    }

    if (isMinimized) {
      isFullscreen = false;
    }

    applyWindowState();
  }

  function toggleFullscreen(force) {
    if (!isOpen) {
      return;
    }

    if (isMinimized) {
      isMinimized = false;
    }

    if (typeof force === 'boolean') {
      isFullscreen = force;
    } else {
      isFullscreen = !isFullscreen;
    }

    applyWindowState();
  }

  $minimizeBtn.on('click', function () {
    toggleMinimize();
  });

  $fullscreenBtn.on('click', function () {
    toggleFullscreen();
  });

  $closeBtn.on('click', function () {
    closeUI(true);
  });

  window.addEventListener('message', function (event) {
    var data = event.data || {};

    if (data.link) {
      pdfLink = data.link;
    }
    if (typeof data.first !== 'undefined') {
      firstView = !!data.first;
    }

    switch (data.action) {
      case 'openui':
        openUI(pdfLink, firstView);
        break;
      case 'closeui':
        closeUI(true);
        break;
      case 'toggleFullscreen':
        toggleFullscreen();
        break;
      default:
        break;
    }
  });

  $(document).on('keydown', function (event) {
    if (!isOpen) {
      return;
    }

    if (event.key === 'Escape') {
      event.preventDefault();
      closeUI(true);
    } else if (event.key === 'Backspace') {
      event.preventDefault();
      toggleMinimize();
    }
  });
});
