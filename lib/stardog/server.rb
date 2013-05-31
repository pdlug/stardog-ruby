module Stardog
  class Server
    attr_accessor :url, :username, :password

    def initialize(params={})
      params.each do |k,v|
        self.send("#{k}=".to_sym, v) if self.respond_to?("#{k}=".to_sym)
      end
      self.url = self.url.sub(/\/+$/, '') unless self.url.nil?
    end


    # Retrieve a handle to a database.
    # @param [String] name the name of the database
    # @return [Database]
    def db(name, opts={})
      Database.new(opts.merge(name: name, server: self))
    end


    # Wrapper around RestClient::Request.execute to set up authentication and provide uniform error
    # handling.
    # @param method [Symbol] HTTP method, any method supported by RestClient (e.g. :get, :post, :head, etc.)
    # @param url [String] URL url relative to the base URL of the server (e.g. '/size', not 'http://.../size')
    # @param opts [Hash<Symbol,Object>] additional options
    # @option opts [Hash] :headers request headers
    # @option opts [Hash] :params URL parameters
    # @option opts [String,IO] :payload request payload for verbs that support it
    # @option opts [String] :username username for basic authentication
    # @option opts [String] :password passwrod for basic authentication
    # @raise [Errors::StardogError]
    # @return [RestClient::Response]
    def execute_request(method, url, opts={})
      req_params = {
        method:   method,
        url:      [self.url, url.sub(/^\//, '')].join('/'),
        headers:  {}
      }
      
      unless opts[:username].blank?
        req_params[:user] = opts[:username]
        req_params[:password] = opts[:password]
      end

      req_params[:payload] = opts[:payload] unless opts[:payload].blank?
      req_params[:headers].merge!(opts[:headers]) unless opts[:headers].blank?
      req_params[:headers][:params] = opts[:params] unless opts[:params].blank?

      begin
        RestClient::Request.execute(req_params) do |response, request, result, &block|
          response.return!(request, result, &block)
        end
      rescue RestClient::Exception => e
        #raise Errors::ServerError, "#{e.http_code}: #{e.http_body}"
        raise Stardog::Errors::StardogError.from_restclient_exception(e)
      end
    end
  end
end