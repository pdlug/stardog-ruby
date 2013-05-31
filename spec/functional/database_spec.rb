require File.dirname(__FILE__) + '/../spec_helper'

describe Stardog::Database do  
  let(:url) { %r{http://[:word:]\.(com|net|org)}.gen }
  let(:name)     { /[:word:]/.gen }
  let(:username) { /[:word:]/.gen }
  let(:password) { /[:word:]/.gen }
  let(:database) { Stardog::Server.new(url: url).db(name, username: username, password: password) }

  describe 'properties' do
    let(:database) { Stardog::Database.new }

    %w(server name username password).each do |p|
      it "should have #{p}" do
        database.should respond_to(p.to_sym)
        database.should respond_to("#{p}=".to_sym)
      end
    end
  end

  describe '#query' do
    let(:sparql)   { 'SELECT DISTINCT ?s WHERE { ?s ?p ?o } LIMIT 10' }
    let(:json) { <<-DATA
      {
        "head" : {
          "vars" : [ "s" ]
        },
        "results" : {
          "bindings" : [ {
            "s" : {
              "type" : "uri",
              "value" : "http://stardog.com/"
            }
          } ]
        }
      }
      DATA
    }

    describe 'succesful results' do
      before do
        @stub = stub_request(:get, %r{/query}).
          with(
            query: hash_including({query: sparql}),
            headers: {
              'Content-Type' => 'text/plain',
              'Accept' => 'application/sparql-results+json'
            }).
          to_return(body: json)
      end

      it 'should execute the query with an authorization header' do
        database.query(sparql).should_not be_nil
        @stub.should have_been_requested
      end

      it 'should return an Enumerable of RDF::Query::Solution' do
        res = database.query(sparql)
        res.should be_a_kind_of(Enumerable)
        res.each do |sol|
          sol.should be_a_kind_of(RDF::Query::Solution)
        end
      end
    end

    describe 'empty results' do
      before do
        stub = stub_request(:get, %r{/query}).
          with(query: hash_including({query: sparql})).
          to_return(body: nil)
      end
      let(:res) { database.query(sparql) }

      it 'should return an empty Enumerable' do
        res.should be_a_kind_of(Enumerable)
        res.should be_empty
      end
    end

    describe 'with reasoning' do
      # SD-Connection-String
      describe 'with valid reasoning type' do
        let(:level) { Stardog::Database::REASONING_LEVELS.to_a.pick }

        before do
          @stub = stub_request(:get, %r{/query}).
            with(
              query: hash_including({query: sparql}),
              headers: {
                'Content-Type' => 'text/plain',
                'Accept' => 'application/sparql-results+json',
                'SD-Connection-String' => "reasoning=#{level}"
              }).
            to_return(body: json)
        end

        it 'should set the reasoning as a key/value pair on SD-Connection-String' do
          database.query(sparql, reasoning: level).should_not be_nil
          @stub.should have_been_requested
        end
      end

      describe 'with invalid reasoning type' do
        it 'should raise an error' do
          expect { database.query(sparql, reasoning: :FOO) }.to raise_error(/Invalid reasoning level/)
        end
      end
    end

    describe 'with :baseURI' do
      let(:baseURI) { %r{http://[:word:]/}.gen }

      it 'should add the baseURI as a query parameter' do
        stub = stub_request(:get, %r{/query}).
          with(query: hash_including(query: sparql, baseURI: baseURI))

        database.query(sparql, baseURI: baseURI).should_not be_nil
        stub.should have_been_requested
      end
    end

    describe 'with :offset' do
      let(:offset) { (0..99).pick }

      it 'should add the offset as a query parameter' do
        stub = stub_request(:get, %r{/query}).
          with(query: hash_including(query: sparql, offset: offset.to_s))

        database.query(sparql, offset: offset)
        stub.should have_been_requested
      end
    end

    describe 'with :limit' do
      let(:limit) { (0..99).pick }

      it 'should add the limit as a query parameter' do
        stub = stub_request(:get, %r{/query}).
          with(query: hash_including(query: sparql, limit: limit.to_s))

        database.query(sparql, limit: limit).should_not be_nil
        stub.should have_been_requested
      end
    end
  end

  describe '#size' do
    let(:size) { (1..9999).pick }

    it 'should return the size of the database' do
      stub_request(:get, %r{/size}).
        to_return(body: size.to_s)

      database.size.should == size
    end
  end

  describe '#transaction' do
    let(:txid) { /\d{10}/.gen }

    before do
      stub_request(:post, %r{/transaction/begin}).
        to_return(body: txid)
    end

    it 'should return transaction' do
      database.transaction.should be_a_kind_of(Stardog::Transaction)
      database.transaction.id.should == txid
    end
  end
end