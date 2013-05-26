module Stardog
  module Errors
    # Base class
    class StardogError < StandardError; end

    # Generic or unknown error on the server
    class ServerError < StardogError; end

    # Client attempted an operation that conflicts with existing state on the server
    class Conflict < StardogError; end

    # Unauthorized 
    class Unauthorized < StardogError; end
  end
end