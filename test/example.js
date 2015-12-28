var fs = require('fs')
var test = require('tape')
var pegjs = require('pegjs-require')

test('Parse zonefile for example.org.', function (t) {
  var zone = fs.readFileSync(__dirname  + '/example.zone', 'utf8')
  var parser = require('../zonefile.pegjs')
  var actual = parser.parse(zone)
  var expected = require('./example.json')
  t.deepEquals(actual, expected, 'Most excellent: Parser generates expected output for example.org.')
  t.end()
})
