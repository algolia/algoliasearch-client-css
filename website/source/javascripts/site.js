// This is where it all goes :)
// 
var header = new communityHeader();

$(function() {
  var cta = $('#cta');
  var messages = [
    'Really?',
    'Are you sure?',
    'Ok, one more click...'
  ];
  cta.on('click', function(event) {
    event.preventDefault();

    var nextMessage = messages.shift();
    if (!nextMessage) {
      $(this).hide();
      console.info('Do something');
      return;
    }
    $(this).text(nextMessage);

  });
});

