$(function() {
  var modal = $('#modal');
  var cta = $('#cta');
  var ctaMessages = [
    'Really?',
    'Are you sure?',
    'Ok, one more click...',
  ];
  var ctaMessageIndex = 0;

  // Init the Community header
  new communityHeader();

  window.App = {
    trollMe: function() {
      new Favico().image($('#trollface')[0]);
    },

    showModal: function() {
      modal.removeClass('hidden');
      App.trollMe();
      $(document).on('keydown', App.onKeyDownEscape);
    },
    closeModal: function() {
      modal.addClass('hidden');
      $(document).off('keydown', App.onKeyDownEscape);
    },
    onKeyDownEscape: function(event) {
      if (event.keyCode !== 27) {
        return;
      }
      App.closeModal();
    },
    onclickCTA: function(event) {
      var message = ctaMessages[ctaMessageIndex++];
      event.preventDefault();
      if (!message) {
        App.showModal();
        ctaMessageIndex = 0;
        cta.text('Download v1.4.17');
      }
      cta.text(message);
    },

    displayMessage: function(e) {
      var message = $('.message-holder');
      message.addClass('visible')
    }
  };

  cta.on('click', App.onclickCTA);
  $('.modal--close').on('click', App.closeModal);

  setTimeout(function() {
    console.log('yo')
    App.displayMessage()
  }, 2500)
});
