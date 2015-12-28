require('pegjs-require')
var parser = require('../zonefile.pegjs')
var test = require('tape')

test('Minimal example', function (t) {
  var actual = parser.parse('tableflip.io. 21599 IN A 178.62.82.182')
  var expected = { origin: null, ttl: null, records:[ { name:'tableflip.io.', ttl: '21599', type:'A', data: '178.62.82.182' } ] }
  t.deepEquals(actual, expected, 'Parser handles individual Resource Records')
  t.end()
})
