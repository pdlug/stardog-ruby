require File.dirname(__FILE__) + '/../spec_helper'

describe Stardog::Errors do
  describe Stardog::Errors::StardogError do
    let(:error) { Stardog::Errors::StardogError.new }

    it 'should be a StandardError' do
      error.should be_a_kind_of(StandardError)
    end

    it 'should have an #error_code' do
      error.should respond_to(:error_code)
    end

    describe '#from_response' do
      let(:server) { Stardog::Server.new(url: %r{http://[:word:]\.(com|net|org)}.gen)}

      describe 'given a status code and optional body' do
        describe 'when a SD-Error-Code header is given' do
          let(:code) { Stardog::Errors::SD_ERROR_CODES.keys.pick }
          let(:body) { /[:sentence:]/.gen }

          before do
            stub_request(:get, %r{/size}).
              to_return(status: 500, headers: {'SD-Error-Code' => code}, body: body)
          end

          let(:err) {
            begin
              server.execute_request(:get, '/size')
            rescue Stardog::Errors::StardogError => e; e; end
          }

          it 'should return a Stardog::Errors::StardogError' do
            err.should be_a_kind_of(Stardog::Errors::StardogError)
          end

          it 'should set the error code on the error' do
            err.error_code.should == code
          end

          it 'should include the text for the error code in the message' do
            err.message.should =~ /#{Stardog::Errors::SD_ERROR_CODES[code]}/
          end

          it 'should include the returned body in the message' do
            err.message.should =~ /#{body}/
          end
        end
      end

      describe 'when a message is provided' do
        let(:msg)      { /[:sentence:]/.gen }
        let(:response) { Struct.new('Response', :status, :headers, :body).new(500, {}, '') }
        let(:err)      { Stardog::Errors::StardogError.from_response(response, msg) }

        it 'should use it as #message' do
          err.message.should == msg
        end
      end

      {
        401 => Stardog::Errors::Unauthorized,
        403 => Stardog::Errors::Forbidden,
        404 => Stardog::Errors::NotFound
      }.each do |code,klass|
        it "should return #{klass} for status code #{code}" do
          stub_request(:get, %r{/size}).
            to_return(status: code)

          expect { server.execute_request(:get, '/size') }.to raise_error(klass)
        end
      end
    end
  end
end