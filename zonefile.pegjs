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
  = directives:(Directive / __)* records:(Record / __)* {
    return {
      origin: findNoneOneOrError(directives, 'origin'),
      ttl: findNoneOneOrError(directives, 'ttl'),
      records: records
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
  = '$ORIGIN' _ origin:Domain __ { return { origin: origin } }

TtlDirective
  = '$TTL' _ ttl:Time __ { return { ttl: ttl } }

// ---- Resource Records -------------------------------------------------------

Record
  = ARecord
  / CnameRecord
  / MxRecord
  / NsRecord
  / SoaRecord
  / SrvRecord
  / TxtRecord
  / GenericRecord

ARecord
  = name:Name? ttl:Ttl? Class? type:'A' _ ipAddress:Ipv4 __ {
  	return {
      name: name,
      ttl: ttl,
      type: type,
      data: ipAddress
    }
  }

CnameRecord
  = name:Name? ttl:Ttl? Class? type:'CNAME' _ domain:Domain __ {
  	return {
      name: name,
      ttl: ttl,
      type: type,
      data: domain
    }
  }

NsRecord
  = name:Name? ttl:Ttl? Class? type:'NS' _ nameServer:Domain __ {
  	return {
      name: name,
      ttl: ttl,
      type: type,
      data: nameServer
    }
  }

MxRecord
  = name:Name? ttl:Ttl? Class? type:'MX' _ preference:Integer _ domain:Domain __  {
  	return {
      name: name,
      ttl: ttl,
      type: type,
      data: domain,
      priority: preference
    }
  }

SoaRecord
  = name:Name? ttl:Ttl? Class? type:'SOA' _ nameServer:Domain _ email:Domain _ '(' __ serial:Integer __ refresh:Time __ retry:Time __ expiry:Time __ minimum:Time __ ')' __? {
  	return {
      name: name,
      ttl: ttl,
      type: type,
      data: [nameServer, email, serial, refresh, retry, expiry, minimum].join(' ')
    }
  }

SrvRecord
  = name:Name ttl:Ttl? Class? type:'SRV' _ priority:Integer _ weight:Integer _ port:Integer _ target:Domain __ {
  	return {
      name: name,
      ttl: ttl,
      type: type,
      data: target,
      priority: priority,
      weight: weight,
      port: port
    }
  }

TxtRecord
  = name:Name? ttl:Ttl? Class? type:'TXT' _ strings:( Strings+ / MultiLineStrings ) __ {
  	return {
      name: name,
      ttl: ttl,
      type: type,
      data: strings.join('')
    }
  }

GenericRecord
  = name:Name? ttl:Ttl? Class? type:$[A-Z]+ _ data:Data __ {
  	return {
      name: name,
      ttl: ttl,
      type: type,
      data: data
    }
  }

// ---- Resource Record fields --------------------------------------------------

Name
  = !Class !Type domain:( '@' / Domain ) _ { return domain }

Ttl
  = ttl:Time _ { return ttl }

Class
  = 'IN' _

// Scraped from http://www.iana.org/assignments/dns-parameters/dns-parameters.xhtml
// `Array.from(document.querySelectorAll('#table-dns-parameters-4 td:first-child')).map(el => el.innerText).filter(str => ['Unassigned', 'Private use', 'Reserved'].indexOf(str) === -1)`
Type
  = ('A' / 'NS' / 'MD' / 'MF' / 'CNAME' / 'SOA' / 'MB' / 'MG' / 'MR' / 'NULL' / 'WKS' / 'PTR' / 'HINFO' / 'MINFO' / 'MX' / 'TXT' / 'RP' / 'AFSDB' / 'X25' / 'ISDN' / 'RT' / 'NSAP' / 'NSAP-PTR' / 'SIG' / 'KEY' / 'PX' / 'GPOS' / 'AAAA' / 'LOC' / 'NXT' / 'EID' / 'NIMLOC' / 'SRV' / 'ATMA' / 'NAPTR' / 'KX' / 'CERT' / 'A6' / 'DNAME' / 'SINK' / 'OPT' / 'APL' / 'DS' / 'SSHFP' / 'IPSECKEY' / 'RRSIG' / 'NSEC' / 'DNSKEY' / 'DHCID' / 'NSEC3' / 'NSEC3PARAM' / 'TLSA' / 'SMIMEA' / 'HIP' / 'NINFO' / 'RKEY' / 'TALINK' / 'CDS' / 'CDNSKEY' / 'OPENPGPKEY' / 'CSYNC' / 'SPF' / 'UINFO' / 'UID' / 'GID' / 'UNSPEC' / 'NID' / 'L32' / 'L64' / 'LP' / 'EUI48' / 'EUI64' / 'TKEY' / 'TSIG' / 'IXFR' / 'AXFR' / 'MAILB' / 'MAILA' / '*' / 'URI' / 'CAA' /  'TA' / 'DLV') _+

Data
  = $((!Comment !NewLine .)*)

// ---- TXT specific types -----------------------------------------------------
String
  = '"' txt:$[^"]* '"' { return txt }

Strings
  = str:String _? { return str }

MultiLineString
  = str:String __? { return str }

MultiLineStrings
  = '(' str:MultiLineString+ ')' { return str }

// ---- Common types -----------------------------------------------------------

// http://www.zytrax.com/books/dns/apa/time.html
Time
  = $(Integer [smhdw]i?)

// A dotted quad, e.g. 192.168.0.1
Ipv4
  = $(Octet '.' Octet '.' Octet '.' Octet)

// A decimal octet, 0 to 255
Octet
  = $([0-9] [0-9]? [0-9]?)

// Domain names may be formed from the set of alphanumeric ASCII characters (a-z, A-Z, 0-9), but characters are case-insensitive. In addition the hyphen is permitted if it is surrounded by characters, digits or hyphens, although it is not to start or end a label. Labels are always separated by the full stop (period) character in the textual name representation.
// https://en.wikipedia.org/wiki/Domain_name#Technical_requirements_and_process
Domain
  = Label ('.' Label)* '.'? { return text() }

Label
  = [a-z0-9-_*]i+
// TODO: pervent leading hyphens in domain labels
// = [a-z0-9]i+ / [a-z0-9]i ([a-z0-9]i / '-')* [a-z0-9]i

Integer
  = $('0' / [1-9][0-9]*)

Comment
  = ';' message:$((!NewLine .)*) NewLine? { return message }

_ "Whitespace"
  = [ \t]+

__ "Whitespace or newline"
  = (_ / NewLine / Comment)+

NewLine "end of line"
  = "\n"
  / "\r\n"
  / "\r"
  / "\u2028"
  / "\u2029"
