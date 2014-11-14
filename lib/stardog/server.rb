# encoding: utf-8

require 'base64'

module Stardog
  class Server
    attr_accessor :url, :username, :password

    # @param opts [Hash<Symbol,Object>]
    # @option opts [Symbol] :adapter the Faraday adapter to use (e.g.
    # :net_http, :typhoeus, :patron, :excon, :em_http, etc.)
    def initialize(opts = {})
      opts.each do |k, v|
        send("#{k}=".to_sym, v) if respond_to?("#{k}=".to_sym)
      end
      self.url = url.sub(/\/+$/, '') unless url.nil?
      @conn = Faraday.new(url: url) do |faraday|
        faraday.adapter(opts.fetch(:adapter, :net_http))
      end
    end

    # Retrieve a handle to a database.
    # @param [String] name the name of the database
    # @return [Database]
    def db(name, opts = {})
      Database.new(opts.merge(name: name, server: self))
    end

    # The configured Faraday connection
    # @api :semipublic
    # @yield [Faraday::Connection]
    # @return [Faraday::Connection]
    def connection
      yield @conn if block_given?
      @conn
    end

    # Wrapper around Faraday requests to set up authentication and provide
    # uniform error handling.
    # @param method [Symbol] HTTP method, any method supported by Faraday (e.g.
    #                       :get, :post, :head, :put, etc.)
    # @param url [String] URL url relative to the base URL of the server (e.g.
    #                     '/size', not 'http://.../size')
    # @param opts [Hash<Symbol,Object>] additional options
    # @option opts [Hash] :headers request headers
    # @option opts [Hash] :params URL parameters
    # @option opts [String,IO] :payload request payload for verbs that support
    #                          it
    # @option opts [String] :username username for basic authentication
    # @option opts [String] :password passwrod for basic authentication
    # @raise [Errors::StardogError]
    # @return [Faraday::Response]
    def execute_request(method, url, opts = {})
      response = connection.send(method) do |req|
        req.url(url, opts[:params])

        unless opts[:username].blank?
          req.headers.merge!(
            authorization_headers(opts[:username], opts[:password]))
        end

        req.headers.merge!(opts[:headers]) unless opts[:headers].blank?
        req.body = opts[:payload] unless opts[:payload].blank?
      end

      handle_response(response)
    end

    private

    # Headers required for authorization, must be added to the request to
    # gain access.
    #
    # @param username [String]
    # @param password [String]
    # @return [Hash<String,String>]
    def authorization_headers(username, password)
      encoded = Base64.urlsafe_encode64([username, password].join(':'))

      { 'Authorization' => "Basic #{encoded}" }
    end

    # Handle a response based on the status code, returns the response payload
    # for a successful request or raises an appropriate error.
    #
    # @param [Faraday::Response] response
    # @return [Faraday::Response]
    # @raise [Stardog::Errors::StardogError]
    def handle_response(response)
      case response.status
      when 200..299
        response
      else
        fail Stardog::Errors::StardogError.from_response(response)
      end
    end
  end
end
