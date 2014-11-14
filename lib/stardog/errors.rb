# encoding: utf-8

module Stardog
  module Errors
    SD_ERROR_CODES = {
      0   => 'Authentication error',
      1   => 'Authorization error',
      2   => 'Query evaluation error',
      3   => 'Unknown transaction',
      4   => 'Unknown database',
      5   => 'Database already exists',
      6   => 'Invalid database name',
      7   => 'Resource (user, role, etc) already exists',
      8   => 'Invalid connection parameter(s)',
      9   => 'Invalid database state for the request',
      10  => 'Resource in use',
      11  => 'Resource not found'
    }

    # Base class for errors returned by the Stardog server
    class StardogError < StandardError
      def initialize(message = nil, response = nil)
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
        return @message if @message

        msg = "#{SD_ERROR_CODES[error_code]} HTTP Status=#{@response.status}"
        msg << ", #{@response.body}" if @response.body.present?

        msg
      end

      class << self
        # Factory to create the appropriate error object for a given HTTP
        # response.
        #
        # @param response [Faraday::Response]
        # @param message [String]
        # @return [Stardog::Errors::StardogError]
        def from_response(response, message = nil)
          klass = case response.status
                  when 400 then BadRequest
                  when 401 then Unauthorized
                  when 403 then Forbidden
                  when 404 then NotFound
                  when 409 then Conflict
                  else self
                  end

          klass.new(message, response)
        end
      end
    end

    # Generic or unknown error on the server
    class ServerError < StardogError; end

    # Bad request
    class BadRequest < StardogError; end

    # Client attempted an operation that conflicts with existing state on the
    # server
    class Conflict < StardogError; end

    # Access to resource/operation was unauthorized (or could not be
    # authorized)
    class Unauthorized < StardogError; end

    # Access forbidden to resource/operation
    class Forbidden < StardogError; end

    # Resource not found
    class NotFound < StardogError; end
  end
end
