var fs = require('fs')
var test = require('tape')
var pegjs = require('pegjs-require')

test('Parse SOA records', function (t) {
  var zone = fs.readFileSync(__dirname  + '/soa.zone', 'utf8')
  var parser = require('../zonefile.pegjs')
  var actual = parser.parse(zone)
  var expected = require('./soa.json')
  t.deepEquals(actual.records[0].data, expected.records[0].data, 'Easy: Parser handles fully specified multiline SOA records')
  t.deepEquals(actual.records[1].data, expected.records[1].data, 'Medium: Parser SOA records with parens on the same line as a param')
  t.deepEquals(actual.records[2].data, expected.records[2].data, 'Hard: Parser handles single line SOA records')
  t.deepEquals(actual, expected, 'Most excellent: Parser generates expected output for SOA records')
  t.end()
})
