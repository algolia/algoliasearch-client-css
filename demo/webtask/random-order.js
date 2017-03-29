var _ = require('lodash');

module.exports = function(context, req, res) {
  res.writeHead(200, {
    'Content-Type': 'text/css'
  });

  var counter = 0;
  var max = 93;
  var list = [];
  _.times(max, function(i) { list.push(i); });
  list = _.shuffle(list);
  
  var css = [];
  _.each(list, function(id, order) {
    css.push("#i[value='' i] ~ #h #h" + id + ' { order: ' + order + ' }');
  });
  
  res.end(css.join("\n"));
}

