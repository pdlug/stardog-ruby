require File.dirname(__FILE__) + '/../spec_helper'

describe Stardog::Server do  
  let(:url) { %r{http://[:word:]\.(com|net|org)}.gen }
  let(:server)   { Stardog::Server.new(url: url) }

  describe 'properties' do
    %w(url).each do |p|
      it "should have #{p}" do
        server.should respond_to(p.to_sym)
        server.should respond_to("#{p}=".to_sym)
      end
    end
  end

  describe 'initialization' do
    it 'should remove trailing slashes on URL' do
      server = Stardog::Server.new(url: "#{url}/")
      server.url.should == url
    end
  end

  describe '#db' do
    let(:name) { /[:word:]/.gen }
    let(:db)   { server.db(name) }

    it 'should return a Database with the name set' do
      db.should be_a_kind_of(Stardog::Database)
      db.name.should == name
    end

    it 'should set #server on the database to itself' do
      db.server.should == server
    end

    describe 'given options' do
      let(:user) { /[:word:]/.gen }
      let(:db)   { server.db(name, username: user) }

      it 'should pass options to the Database constructor' do
        db.username.should == user
      end
    end
  end
end