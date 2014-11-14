# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'

describe Stardog::Errors do
  describe Stardog::Errors::StardogError do
    let(:error) { Stardog::Errors::StardogError.new }

    it 'has a StandardError' do
      expect(error).to be_a_kind_of(StandardError)
    end

    it 'has an #error_code' do
      expect(error).to respond_to(:error_code)
    end

    describe '#from_response' do
      let(:server) do
        Stardog::Server.new(url: %r{http://[:word:]\.(com|net|org)}.gen)
      end

      describe 'given a status code and optional body' do
        describe 'when a SD-Error-Code header is given' do
          let(:code) { Stardog::Errors::SD_ERROR_CODES.keys.pick }
          let(:body) { /[:sentence:]/.gen }

          before do
            stub_request(:get, /\/size/)
              .to_return(status: 500,
                         headers: { 'SD-Error-Code' => code },
                         body: body)
          end

          let(:err) do
            begin
              server.execute_request(:get, '/size')
            rescue Stardog::Errors::StardogError => e
              e
            end
          end

          it 'returns a Stardog::Errors::StardogError' do
            expect(err).to be_a_kind_of(Stardog::Errors::StardogError)
          end

          it 'sets the error code on the error' do
            expect(err.error_code).to eq(code)
          end

          it 'includes the text for the error code in the message' do
            expect(err.message)
              .to match(/#{Stardog::Errors::SD_ERROR_CODES[code]}/)
          end

          it 'includes the returned body in the message' do
            expect(err.message).to match(/#{body}/)
          end
        end
      end

      describe 'when a message is provided' do
        let(:msg)      { /[:sentence:]/.gen }

        let(:response) do
          Struct.new('Response', :status, :headers, :body).new(500, {}, '')
        end

        let(:err) do
          Stardog::Errors::StardogError.from_response(response, msg)
        end

        it 'sets #message' do
          expect(err.message).to eq(msg)
        end
      end

      {
        400 => Stardog::Errors::BadRequest,
        401 => Stardog::Errors::Unauthorized,
        403 => Stardog::Errors::Forbidden,
        404 => Stardog::Errors::NotFound
      }.each do |code, klass|
        it "returns #{klass} for status code #{code}" do
          stub_request(:get, /\/size/).to_return(status: code)

          expect do
            server.execute_request(:get, '/size')
          end.to raise_error(klass)
        end
      end
    end
  end
end
