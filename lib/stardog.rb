require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'faraday'
require 'multi_json'
require 'sparql/client'


module Stardog
  class Format
    JSON_LD   = 'application/ld+json'
    N_TRIPLES = 'text/plain'
    NQUADS    = 'text/x-nquads'
    RDF_XML   = 'application/rdf+xml'
    TURTLE    = 'application/x-turtle'
    TRIG      = 'application/x-trig'
    TRIX      = 'application/trix'
  end

  autoload :Database,    'stardog/database'
  autoload :Errors,      'stardog/errors'
  autoload :Server,      'stardog/server'
  autoload :Transaction, 'stardog/transaction'
end