# encoding: utf-8

require 'set'

module Stardog
  class Database
    attr_accessor :server, :name, :username, :password

    REASONING_LEVELS = Set.new([:NONE, :RDFS, :QL, :RL, :EL, :DL])

    def initialize(params = {})
      params.each do |k, v|
        send("#{k}=".to_sym, v) if respond_to?("#{k}=".to_sym)
      end
    end

    # Size of the database (number of triples)
    # @return [Integer]
    def size
      execute_request(:get, '/size').body.to_i
    end

    # Execute a SPARQL query
    #
    # @param sparql [String] the SPARQL query
    # @param opts [Hash] the options
    # @option opts [Symbol] :reasoning the reasoning level to apply
    #                                  (NONE, RDFS, QL, RL, EL, DL)
    # @option opts [String] :baseURI
    # @option opts [Integer] :limit
    # @option opts [Integer] :offset
    def query(sparql, opts = {})
      res = execute_request(
        :get,
        '/query',
        params:  opts.slice(:baseURI, :offset, :limit).merge(query: sparql),
        headers: request_headers(opts)
      ).body

      res.blank? ? [] : SPARQL::Client.parse_json_bindings(res)
    end

    # Begin a transaction
    #
    # @return [Transaction]
    def transaction(&block)
      Transaction.new(self).start(&block)
    end

    # Execute an HTTP request relative to the base URL of this database
    #
    # @see Server#execute_request
    def execute_request(method, url, opts = {})
      server.execute_request(
        method,
        [name, url.sub(/^\//, '')].join('/'),
        opts.merge(username: username, password: password))
    end

    private

    # Generate the headers for a request given the options.
    #
    # @return [Hash<Symbol,Object>] headers to use for the request
    def request_headers(opts)
      headers = {
        accept:       'application/sparql-results+json',
        content_type: 'text/plain'
      }

      unless opts[:reasoning].blank?
        unless REASONING_LEVELS.member?(opts[:reasoning])
          fail "Invalid reasoning level: #{opts[:reasoning]}"
        end
        headers['SD-Connection-String'] = "reasoning=#{opts[:reasoning]}"
      end

      headers
    end
  end
end
