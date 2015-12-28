# zonefile-pegjs

A PEG.js grammar for parsing zonefile DNS configuration to JSON. Handles **multi-line SOA and TXT records**, as well as **SRV, MX, CNAME, NS, AAAA, A** and friends.

See **[zonefile.pegjs](https://github.com/tableflip/zonefile-pegjs/blob/master/zonefile.pegjs)** for the magic. You can try it out by pasting it into the PEG.js web dingus: http://pegjs.org/online

Derived from, and with thanks to, **Pro DNS and BIND by Ron Aitchison**.
See: http://www.zytrax.com/books/dns/ch8/

## Install

```sh
npm install zonefile-pegjs
```

## Usage

Use [pegjs](https://www.npmjs.com/package/pegjs) to build the parser, or use [pegjs-require](https://www.npmjs.com/package/pegjs-require) to `require` the grammar file directly:

```js
require('pegjs-require')
var parser = require('zonefile-pegjs')
parser.parse('tableflip.io. 21599 IN A 178.62.82.182')
// { origin: null, ttl: null, records:[ { name:'tableflip.io.', ttl: '21599', type:'A', data: '178.62.82.182' } ] }
```

## Example

[**example.js**](https://github.com/tableflip/zonefile-pegjs/blob/master/test/example.js)

```js
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
```

So given zonefile like: [**example.zone**](https://github.com/tableflip/zonefile-pegjs/blob/master/test/example.zone)

```zonefile
; zone file for example.org
$TTL 2d    ; 172800 secs default TTL for zone
$ORIGIN example.org.
@             IN      SOA   ns1.example.org. hostmaster.example.org. (
                        2003080800 ; se = serial number
                        12h        ; ref = refresh
                        15m        ; ret = update retry
                        3w         ; ex = expiry
                        3h         ; min = minimum
                        )
              IN      NS      ns1.example.org.
              IN      MX  10  mail.example.org.
joe           IN      A       192.168.254.3
www           IN      CNAME   joe
```

The parser will produce: [**example.json**](https://github.com/tableflip/zonefile-pegjs/blob/master/test/example.json)

```json
{
  "origin": "example.org.",
  "ttl": "2d",
  "records": [
    {
      "name": "@",
      "ttl": null,
      "type": "SOA",
      "data": {
        "nameServer": "ns1.example.org.",
        "email": "hostmaster.example.org.",
        "serial": "2003080800",
        "refresh": "12h",
        "retry": "15m",
        "expiry": "3w",
        "minimum": "3h"
      }
    },
    {
      "name": " ",
      "ttl": null,
      "type": "NS",
      "data": "ns1.example.org."
    },
    {
      "name": " ",
      "ttl": null,
      "type": "MX",
      "data": {
        "preference": "10",
        "domain": "mail.example.org."
      }
    },
    {
      "name": "joe",
      "ttl": null,
      "type": "A",
      "data": "192.168.254.3"
    },
    {
      "name": "www",
      "ttl": null,
      "type": "CNAME",
      "data": "joe"
    }
  ]
}
```

