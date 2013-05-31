module Stardog
  module Errors
    SD_ERROR_CODES = {
      0  => 'Failure with the authentication of the user.',
      1  => 'Failure of the authorization of the user.',
      2  => 'Error during Query evaluation.',
      3  => 'The transaction specified in the request was not found.',
      4  => 'The database specified in the request was not found.',
      5  => 'The request could not be completed because the database already exists.',
      6  => 'The request could not be completed because the database name is not valid.',
      7  => 'The request could not be completed because the resource already exists.',
      8  => 'The request could not be completed because the connection configuration is invalid.',
      9  => 'The request could not be completed because the database is not in the correct state.',
      10 => ' The request could not be completed because the resource is in use.',
      11 => ' The request could not be completed because the resource is not found.'
    }

    # Base class for errors returned by the Stardog server
    class StardogError < StandardError
      def initialize(message=nil, response=nil)
        @message = message
        @response = response
      end

      def error_code
        code = @response.try(:headers).try(:[], :sd_error_code)
        code.blank? ? nil : code.to_i 
      end

      def inspect
        "<#{self.class.name}: #{message}>"
      end

      def message
        @message || "#{SD_ERROR_CODES[self.error_code]} HTTP Status=#{@response.status}, #{@response.body}"
      end

      class << self
        # Factory to create the appropriate error object for a given HTTP response.
        # @param res [Faraday::Response]
        # @param message [String]
        # @return [Stardog::Errors::StardogError]
        def from_response(response, message=nil)
          klass = case response.status
          when 401
            Unauthorized
          when 403
            Forbidden
          when 404
            NotFound
          when 409
            Conflict
          else
            self
          end

          klass.new(message, response)
        end
      end
    end

    # Generic or unknown error on the server
    class ServerError < StardogError; end

    # Client attempted an operation that conflicts with existing state on the server
    class Conflict < StardogError; end

    # Access to resource/operation was unauthorized (or could not be authorized)
    class Unauthorized < StardogError; end

    # Access forbidden to resource/operation
    class Forbidden < StardogError; end

    # Resource not found
    class NotFound < StardogError; end
  end
end