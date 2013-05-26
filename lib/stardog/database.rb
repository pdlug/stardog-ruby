module Stardog
  class Database
    attr_accessor :url, :name, :username, :password

    def initialize(params={})
      params.each do |k,v|
        self.send("#{k}=".to_sym, v) if self.respond_to?("#{k}=".to_sym)
      end
      self.url = self.url.sub(/\/+$/, '') unless self.url.nil?
    end


    # Size of the database (number of triples)
    # @return [Integer]
    def size
      self.execute_request(:get, "#{self.url}/size")[0..-1].to_i
    end


    # Execute a SPARQL query
    # @param sparql [String] the SPARQL query
    # @param opts [Hash] the options
    # @option opts [String] :baseURI
    # @option opts [Integer] :limit
    # @option opts [Integer] :offset
    def query(sparql, opts={})
      res = self.execute_request(
        :get,
        "#{self.url}/#{self.name}/query",
        params:       opts.slice(:baseURI, :offset, :limit).merge(query: sparql),
        headers: {
          accept:       'application/sparql-results+json',
          content_type: 'text/plain'
        }
      )

      res.blank? ? [] : SPARQL::Client.parse_json_bindings(res)
    end


    # Begin a transaction
    # @return [Transaction]
    def transaction(&block)
      Transaction.new(self).start(&block)
    end


    # Wrapper around RestClient::Request.execute to set up authentication and provide uniform error
    # handling.
    # @param method [Symbol] HTTP method, any method supported by RestClient (e.g. :get, :post, :head, etc.)
    # @param url [String] URL
    # @param opts [Hash<Symbol,Object>] additional options
    # @option opts [Hash] :headers request headers
    # @option opts [Hash] :params URL parameters
    # @option opts [nil,String,IO] :payload request payload for verbs that support it
    # @raise [Errors::StardogError]
    # @return [RestClient::Response]
    def execute_request(method, url, opts={})
      req_params = {
        method:   method,
        url:      url,
        headers:  {},
        user:     self.username,
        password: self.password
      }

      req_params[:payload] = opts[:payload] unless opts[:payload].blank?
      req_params[:headers].merge!(opts[:headers]) unless opts[:headers].blank?
      req_params[:headers][:params] = opts[:params] unless opts[:params].blank?

      begin
        RestClient::Request.execute(req_params)
      rescue RestClient::Conflict
        raise Errors::Conflict
      rescue RestClient::Unauthorized
        raise Errors::Unauthorized
      rescue RestClient::Exception => e
        raise Errors::ServerError, "#{e.http_code}: #{e.http_body}"
      end
    end
  end
end