module Stardog
  class TransactionConflict < StandardError; end

  class Transaction
    attr_accessor :id, :database

    def initialize(database)
      @database = database
      @state = :created
    end


    # Start a transaction on the server and store the ID.
    # @yield [Transaction]
    # @return [Transaction]
    def start(&block)
      res = self.database.execute_request(
        :post,
        "/transaction/begin",
        headers: {
          content_type: 'text/plain'
        }
      )
      self.id = res
      @state = :started
      self.instance_eval(&block) if block_given?
      self
    end


    # Commit this transaction
    # @raise [TransactionConflict] if the transaction has not been started yet or was already committed
    # @return [true,false]
    def commit
      raise TransactionConflict, "Unable to commit, transaction not started yet" unless self.started?

      begin
        self.database.execute_request(
          :post,
          "/transaction/commit/#{self.id}",
          headers: {
            content_type: 'text/plain'
          }
        )
        @state = :committed
      rescue Errors::Conflict
        raise TransactionConflict, "Conflict - Transaction already committed"
      end

      true
    end


    # Rollback this transaction
    # @raise [TransactionConflict] if the transaction has not been started yet or was already rolled back
    # @return [true,false]
    def rollback
      raise TransactionConflict, "Unable to rollback, transaction not started yet" unless self.started?

      begin
        self.database.execute_request(
          :post,
          "/transaction/rollback/#{self.id}",
          headers: {
            content_type: 'text/plain'
          }
        )
        @state = :rolledback
      rescue Errors::Conflict
        raise TransactionConflict, "Conflict - Transaction already rolled back"
      end

      true
    end


    # Add statements to the database.
    # @param data [String]
    # @param format [Format]
    # @param graph_uri [String]
    # @return [true,false]
    def add(data, format=Format::RDF_XML, graph_uri=nil)
      req_params = {
        payload: data,
        headers: {
          content_type: format
        }
      }
      req_params[:params] = {'graph-uri' => graph_uri} if graph_uri

      self.database.execute_request(:post, "/#{self.id}/add", req_params)

      true
    end


    # Remove statements from the database.
    # @param data [String]
    # @param format [Format]
    # @param graph_uri [String]
    # @return [true,false]
    def remove(data, format=Format::RDF_XML, graph_uri=nil)
      req_params = {
        payload: data,
        headers: {
          content_type: format
        }
      }
      req_params[:params] = {'graph-uri' => graph_uri} if graph_uri

      self.database.execute_request(:post, "/#{self.id}/remove", req_params)

      true
    end


    # Clear all data out of the database (or just the data specified by the named graph URI).
    # @param graph_uri [String]
    # @return [true,false]
    def clear(graph_uri=nil)
      req_params = {}
      req_params[:params] = {'graph-uri' => graph_uri} if graph_uri

      self.database.execute_request(:post, "/#{self.id}/clear", req_params)

      true
    end


    # Whether or not this transaction has been started (has an ID and ready
    # to accept operations)
    # @return [true,false]
    def started?
      @state != :created
    end


    # Whether or not this transaction has been committed
    # @return [true,false]
    def committed?
      @state == :committed
    end
  end
end