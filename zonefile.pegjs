/*

A PEG.js grammar for parsing zonefile DNS configuration to JSON.
Copyright (C) 2015 Oli Evans <oli@tableflip.io>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

// Start rule: A zonefile is Directives followed by Records, and possibly blank lines or comments.
Zonefile
  = directives:(Directive / BlankLine)* records:(Record / BlankLine)* {
    return {
      origin: findNoneOneOrError(directives, 'origin'),
      ttl: findNoneOneOrError(directives, 'ttl'),
	  records: records.filter(r => !Array.isArray(r)) // Remove blank lines / comments
    }
    function findNoneOneOrError (arr, prop) {
      var results = arr.filter(item => !!item[prop])
      if (results.length === 0) return null
      if (results.length === 1) return results[0][prop]
      return error('Zonefile has ' + results.length + ' $' + prop.toUpperCase() + ' directives. A valid zonefile has 1 or none.')
    }
  }

// ---- Directives -------------------------------------------------------------

// TODO: support for $INCLUDE & $GENERATE directives
Directive
  = TtlDirective / OriginDirective

OriginDirective
  = '$ORIGIN' _ origin:Domain EOL? { return { origin: origin } }

TtlDirective
  = '$TTL' _ ttl:Time EOL? { return { ttl: ttl } }

// ---- Resource Records -------------------------------------------------------

Record
  = ARecord / AaaaRecord / CnameRecord / MxRecord / NsRecord / SrvRecord / SoaRecord / TxtRecord / GenericRecord

ARecord
  = intro:RecordIntro type:'A' _+ address:Ipv4 __ {
  	return {
      name: intro.name,
      ttl: intro.ttl,
      type: type,
      data: address
    }
  }

AaaaRecord
  = intro:RecordIntro type:'AAAA' _+ address:Ipv6 __ {
  	return {
      name: intro.name,
      ttl: intro.ttl,
      type: type,
      data: address
    }
  }

CnameRecord
  = intro:RecordIntro type:'CNAME' _+ domain:Domain __ {
  	return {
      name: intro.name,
      ttl: intro.ttl,
      type: type,
      data: domain
    }
  }

MxRecord
  = intro:RecordIntro type:'MX' _+ preference:Integer _+ domain:Domain EOL?  {
  	return {
      name: intro.name,
      ttl: intro.ttl,
      type: type,
      data: { preference: preference, domain: domain }
    }
  }

NsRecord
  = intro:RecordIntro type:'NS' _+ nameServer:Domain EOL? {
  	return {
      name: intro.name,
      ttl: intro.ttl,
      type: type,
      data: nameServer
    }
  }

SoaRecord
  = intro:RecordIntro type:'SOA' _+ nameServer:Domain _+ email:Domain _+ '(' __+ serial:Integer __+ refresh:Time __+ retry:Time __+ expiry:Time __+ minimum:Time __* ')' EOL? {
  	return {
      name: intro.name,
      ttl: intro.ttl,
      type: type,
      data: { nameServer: nameServer, email:email, serial:serial, refresh:refresh, retry:retry, expiry:expiry, minimum:minimum }
    }
  }

SrvRecord
  = intro:RecordIntro type:'SRV' _+ priority:Integer _+ weight:Integer _+ port:Integer _+ target:Domain EOL? {
  	return {
      name: intro.name,
      ttl: intro.ttl,
      type: type,
      data: { priority: priority, weight: weight, port: port, target: target }
    }
  }

TxtRecord
  = intro:RecordIntro type:'TXT' _+ strings:( Strings+ / MultiLineStrings ) EOL? {
  	return {
      name: intro.name,
      ttl: intro.ttl,
      type: type,
      data: strings.join('')
    }
  }

GenericRecord
  = intro:RecordIntro type:Type _+ data:Data EOL? {
  	return {
      name: intro.name,
      ttl: intro.ttl,
      type: type,
      data: data
    }
  }

RecordIntro
  = name:Name _* ttl:Time? _* Class? _* {
    return {
      name:name,
      ttl: ttl
    }
  }

// ---- Resource Record fields --------------------------------------------------

// Name of the node in the zone to which this record belongs.
// `@` means "replace with the current value of $ORIGIN"
// `blank/space or tab` means "replace with last name used or the value of $ORIGIN"
// http://www.zytrax.com/books/dns/ch8/#generic
Name
  = !Class !Type name:(_ / '@' / Domain) { return name }

Class
  = 'IN'

// Scraped from http://www.iana.org/assignments/dns-parameters/dns-parameters.xhtml
// `Array.from(document.querySelectorAll('#table-dns-parameters-4 td:first-child')).map(el => el.innerText).filter(str => ['Unassigned', 'Private use', 'Reserved', '*'].indexOf(str) === -1).sort().reverse()`
// We sort and reverse to avoid matching things like 'A', for a value 'AAAA'. PEG matching is implicitly ordered.
Type
  = 'X25' /  'WKS' / 'URI' / 'UNSPEC' / 'UINFO' / 'UID' / 'TXT' / 'TSIG' / 'TLSA' / 'TKEY' / 'TALINK' / 'TA' / 'SSHFP' / 'SRV' / 'SPF' / 'SOA' / 'SMIMEA' / 'SINK' / 'SIG' / 'RT' / 'RRSIG' / 'RP' / 'RKEY' / 'PX' / 'PTR' / 'OPT' / 'OPENPGPKEY' / 'NXT' / 'NULL' / 'NSEC3PARAM' / 'NSEC3' / 'NSEC' / 'NSAP-PTR' / 'NSAP' / 'NS' / 'NINFO' / 'NIMLOC' / 'NID' / 'NAPTR' / 'MX' / 'MR' / 'MINFO' / 'MG' / 'MF' / 'MD' / 'MB' / 'MAILB' / 'MAILA' / 'LP' / 'LOC' / 'L64' / 'L32' / 'KX' / 'KEY' / 'IXFR' / 'ISDN' / 'IPSECKEY' / 'HIP' / 'HINFO' / 'GPOS' / 'GID' / 'EUI64' / 'EUI48' / 'EID' / 'DS' / 'DNSKEY' / 'DNAME' / 'DLV' / 'DHCID' / 'CSYNC' / 'CNAME' / 'CERT' / 'CDS' / 'CDNSKEY' / 'CAA' / 'AXFR' / 'ATMA' / 'APL' / 'AFSDB' / 'AAAA' / 'A6' / 'A'

// Generic data matcher. Used where we don't have a type specific Record rule.
Data
  = $((!EOL .)*)

// ---- Common types -----------------------------------------------------------

// Domain names may be formed from the set of alphanumeric ASCII characters (a-z, A-Z, 0-9), but characters are case-insensitive. In addition the hyphen is permitted if it is surrounded by characters, digits or hyphens, although it is not to start or end a label. Labels are always separated by the full stop (period) character in the textual name representation.
// https://en.wikipedia.org/wiki/Domain_name#Technical_requirements_and_process
Domain
  = $(Label ('.' Label)* '.'?)

Label
  = [a-z0-9-_\*]i+
// TODO: pervent leading hyphens in domain labels
// = [a-z0-9]i+ / [a-z0-9]i ([a-z0-9]i / '-')* [a-z0-9]i

// http://www.zytrax.com/books/dns/apa/time.html
Time
  = $((Integer [smhdw]i)+ / Integer)

// A dotted quad, e.g. 192.168.0.1
Ipv4
  = $(Octet '.' Octet '.' Octet '.' Octet)

// A decimal octet, 0 to 255
Octet
  = $([0-9] [0-9]? [0-9]?)

// Eight groups of four hexadecimal digits, with leading 0 and all 0 groups optionally ommitted
// e.g :: to 2001:0db8:85a3:0000:0000:8a2e:0370:7334
Ipv6
  = $(HexGroup ':' HexGroup ':' (HexGroup ':')? (HexGroup ':')? (HexGroup ':')? (HexGroup ':')? (HexGroup ':')? HexGroup)

HexGroup
  = Hex? Hex? Hex? Hex?

Hex
  = [0-9a-f]i

Integer
  = $('0' / [1-9][0-9]*)

Comment "Comment"
  = ';' message:$((!Newline .)*) Newline? { return message }

BlankLine
  = EOL

EOL
  = _* (Newline / Comment)

Newline "Newline"
  = '\n' / '\r\n' / '\r' / '\u2028' / '\u2029'

__ "Whitespace or Newline"
  = ( _ / Newline / Comment )

_ "Whitespace"
  = [ \t]

// ---- TXT specific types -----------------------------------------------------
String
  = '"' txt:$[^"]* '"' { return txt }

Strings
  = str:String _? { return str }

MultiLineString
  = str:String __* { return str }

MultiLineStrings
  = '(' str:MultiLineString+ ')' { return str }
