# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe Stardog::Database do
  let(:url) { %r{http://[:word:]\.(com|net|org)}.gen }
  let(:name)     { /[:word:]/.gen }
  let(:username) { /[:word:]/.gen }
  let(:password) { /[:word:]/.gen }
  let(:database) do
    Stardog::Server.new(url: url)
      .db(name, username: username, password: password)
  end

  describe 'properties' do
    let(:database) { Stardog::Database.new }

    %w(server name username password).each do |p|
      it "has a property #{p}" do
        expect(database).to respond_to(p.to_sym)
        expect(database).to respond_to("#{p}=".to_sym)
      end
    end
  end

  describe '#query' do
    let(:sparql)   { 'SELECT DISTINCT ?s WHERE { ?s ?p ?o } LIMIT 10' }
    let(:json) do
      <<-DATA
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
    end

    describe 'succesful results' do
      let!(:stub) do
        stub_request(:get, /\/query/)
          .with(
            query: hash_including(query: sparql),
            headers: {
              'Content-Type' => 'text/plain',
              'Accept' => 'application/sparql-results+json'
            })
          .to_return(body: json)
      end

      it 'executes the query with an authorization header' do
        expect(database.query(sparql)).not_to be_nil
        expect(stub).to have_been_requested
      end

      it 'returns an Enumerable of RDF::Query::Solution' do
        res = database.query(sparql)
        expect(res).to be_a_kind_of(Enumerable)
        res.each do |sol|
          expect(sol).to be_a_kind_of(RDF::Query::Solution)
        end
      end
    end

    describe 'empty results' do
      before do
        stub_request(:get, /\/query/)
          .with(query: hash_including(query: sparql))
          .to_return(body: nil)
      end
      let(:res) { database.query(sparql) }

      it 'returns an empty Enumerable' do
        expect(res).to be_a_kind_of(Enumerable)
        expect(res).to be_empty
      end
    end

    describe 'with reasoning' do
      describe 'with valid reasoning type' do
        let(:level) { Stardog::Database::REASONING_LEVELS.to_a.pick }

        let!(:stub) do
          stub_request(:get, /\/query/)
            .with(
              query: hash_including(query: sparql),
              headers: {
                'Content-Type' => 'text/plain',
                'Accept' => 'application/sparql-results+json',
                'SD-Connection-String' => "reasoning=#{level}"
              })
            .to_return(body: json)
        end

        it 'sets the reasoning as a key/value pair on SD-Connection-String' do
          expect(database.query(sparql, reasoning: level)).not_to be_nil
          expect(stub).to have_been_requested
        end
      end

      describe 'with invalid reasoning type' do
        it 'raises an error' do
          expect do
            database.query(sparql, reasoning: :FOO)
          end.to raise_error(/Invalid reasoning level/)
        end
      end
    end

    describe 'with :baseURI' do
      let(:baseURI) { %r{http://[:word:]/}.gen }
      let!(:stub) do
        stub_request(:get, /\/query/)
          .with(query: hash_including(query: sparql, baseURI: baseURI))
      end

      it 'adds the baseURI as a query parameter' do
        expect(database.query(sparql, baseURI: baseURI)).not_to be_nil
        expect(stub).to have_been_requested
      end
    end

    describe 'with :offset' do
      let(:offset) { (0..99).pick }
      let!(:stub) do
        stub_request(:get, /\/query/)
          .with(query: hash_including(query: sparql, offset: offset.to_s))
      end

      it 'adds the offset as a query parameter' do
        database.query(sparql, offset: offset)
        expect(stub).to have_been_requested
      end
    end

    describe 'with :limit' do
      let(:limit) { (0..99).pick }
      let!(:stub) do
        stub_request(:get, /\/query/)
          .with(query: hash_including(query: sparql, limit: limit.to_s))
      end

      it 'adds the limit as a query parameter' do
        expect(database.query(sparql, limit: limit)).not_to be_nil
        expect(stub).to have_been_requested
      end
    end
  end

  describe '#size' do
    let(:size) { (1..9999).pick }

    it 'returns the size of the database' do
      stub_request(:get, /\/size/)
        .to_return(body: size.to_s)

      expect(database.size).to eq(size)
    end
  end

  describe '#transaction' do
    let(:txid) { /\d{10}/.gen }

    before do
      stub_request(:post, %r{/transaction/begin})
        .to_return(body: txid)
    end

    it 'returns a transaction' do
      expect(database.transaction).to be_a_kind_of(Stardog::Transaction)
      expect(database.transaction.id).to eq(txid)
    end
  end
end
