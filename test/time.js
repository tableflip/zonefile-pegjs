var fs = require('fs')
var test = require('tape')
var pegjs = require('pegjs-require')

test('Parse time values', function (t) {
  var zone = fs.readFileSync(__dirname  + '/time.zone', 'utf8')
  var parser = require('../zonefile.pegjs')
  var actual = parser.parse(zone)
  var expected = require('./time.json')
  t.deepEquals(actual, expected, 'Parser generates expected output for various time formats')
  t.end()
})
