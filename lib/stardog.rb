require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/object/blank'
require 'multi_json'
require 'restclient'
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
  autoload :Transaction, 'stardog/transaction'
end