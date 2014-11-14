# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe Stardog::Server do
  let(:url) { %r{http://[:word:]\.(com|net|org)}.gen }
  let(:server)   { Stardog::Server.new(url: url) }

  describe 'properties' do
    %w(url).each do |p|
      it "has a property #{p}" do
        expect(server).to respond_to(p.to_sym)
        expect(server).to respond_to("#{p}=".to_sym)
      end
    end
  end

  describe 'initialization' do
    it 'removes trailing slashes on URL' do
      server = Stardog::Server.new(url: "#{url}/")
      expect(server.url).to eq(url)
    end

    it 'defaults to using the :net_http Faraday adapter' do
      expect(server.connection.builder.handlers)
        .to eq([Faraday::Adapter::NetHttp])
    end

    describe 'when :adapter is given' do
      let(:server)  { Stardog::Server.new(adapter: :test) }

      it 'configures the Faraday connection to use the provided adapter' do
        expect(server.connection.builder.handlers)
          .to eq([Faraday::Adapter::Test])
      end
    end
  end

  describe '#db' do
    let(:name) { /[:word:]/.gen }
    let(:db)   { server.db(name) }

    it 'returns a Database with the name set' do
      expect(db).to be_a_kind_of(Stardog::Database)
      expect(db.name).to eq(name)
    end

    it 'sets #server on the database to itself' do
      expect(db.server).to eq(server)
    end

    describe 'given options' do
      let(:user) { /[:word:]/.gen }
      let(:db)   { server.db(name, username: user) }

      it 'passes options to the Database constructor' do
        expect(db.username).to eq(user)
      end
    end
  end
end
