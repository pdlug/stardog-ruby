# encoding: utf-8

require File.dirname(__FILE__) + '/../spec_helper'

describe Stardog::Transaction do
  let(:url)         { %r{http://[:word:]\.(com|net|org)}.gen }
  let(:name)        { /[:word:]/.gen }
  let(:database) do
    Stardog::Server.new(url: url)
      .db(name, username: /[:word:]/.gen, password: /[:word:]/.gen)
  end

  let(:transaction) { Stardog::Transaction.new(database) }

  let(:txid) { /\d{10}/.gen }

  describe 'initialization' do
    it 'accepts a Database' do
      expect(transaction).not_to be_nil
      expect(transaction.database).to eq(database)
    end
  end

  describe '#start' do
    before do
      stub_request(:post, %r{/transaction/begin})
        .to_return(body: txid)
      @retval = transaction.start
    end

    it 'starts a transaction on the server, sets the ID to the one returned' do
      expect(transaction.id).to eq(txid)
    end

    it 'returns the transaction' do
      expect(@retval).to eq(transaction)
    end

    it 'marks the transaction as started' do
      expect(transaction).to be_started
    end
  end

  describe '#commit' do
    describe 'transaction not started' do
      it 'raises an exception' do
        expect do
          transaction.commit
        end.to raise_error(Stardog::TransactionConflict)
      end
    end

    describe 'transaction started' do
      describe 'successful commit' do
        before do
          stub_request(:post, %r{/#{name}/transaction/begin})
            .to_return(body: txid)
          transaction.start

          stub_request(:post, %r{/transaction/commit/#{txid}})

          @retval = transaction.commit
        end

        it 'returns true' do
          expect(@retval).to eq(true)
        end

        it 'is committed' do
          expect(transaction).to be_committed
        end
      end

      describe 'duplicate commit (or other conflict)' do
        before do
          stub_request(:post, %r{/#{name}/transaction/begin})
            .to_return(body: txid)
          transaction.start

          stub_request(:post, %r{/transaction/commit/#{txid}})
          transaction.commit

          stub_request(:post, %r{/transaction/commit/#{txid}})
            .to_return(status: 409)
        end

        it 'returns true' do
          expect do
            transaction.commit
          end.to raise_error(Stardog::TransactionConflict)
        end

        it 'is committed' do
          expect(transaction).to be_committed
        end
      end
    end
  end

  describe '#rollback' do
    describe 'transaction not started' do
      it 'raises an exception' do
        expect do
          transaction.rollback
        end.to raise_error(Stardog::TransactionConflict)
      end
    end

    describe 'transaction started' do
      describe 'successful rollback' do
        before do
          stub_request(:post, %r{/#{name}/transaction/begin})
            .to_return(body: txid)
          transaction.start

          stub_request(:post, %r{/transaction/rollback/#{txid}})

          @retval = transaction.rollback
        end

        it 'returns true' do
          expect(@retval).to eq(true)
        end

        it 'is not committed' do
          expect(transaction).not_to be_committed
        end
      end

      describe 'duplicate rollback (or other conflict)' do
        before do
          stub_request(:post, %r{/#{name}/transaction/begin})
            .to_return(body: txid)
          transaction.start

          stub_request(:post, %r{/transaction/rollback/#{txid}})
          transaction.rollback

          stub_request(:post, %r{/transaction/rollback/#{txid}})
            .to_return(status: 409)
        end

        it 'returns true' do
          expect do
            transaction.rollback
          end.to raise_error(Stardog::TransactionConflict)
        end

        it 'is not committed' do
          expect(transaction).not_to be_committed
        end
      end
    end
  end

  describe '#add' do
    let(:data) do
      '<http://www.stardog.com/> <http://purl.org/dc/elements/1.1/title> '\
      '"Stardog" .'
    end

    before do
      stub_request(:post, %r{/#{name}/transaction/begin})
        .to_return(body: txid)

      transaction.start

      stub_request(:post, %r{/#{name}/#{txid}/add})
        .with(body: data,
              headers: { 'Content-Type' => Stardog::Format::N_TRIPLES })
        .to_return(status: 200)
    end

    it 'returns true' do
      expect(transaction.add(data, Stardog::Format::N_TRIPLES)).to eq(true)
    end
  end

  describe '#remove' do
    let(:data) do
      '<http://stardog.com/> <http://purl.org/dc/elements/1.1/title> '\
      '"Stardog" .'
    end

    before do
      stub_request(:post, %r{/#{name}/transaction/begin})
        .to_return(body: txid)

      transaction.start

      stub_request(:post, %r{/#{name}/#{txid}/remove})
        .with(body: data,
              headers: { 'Content-Type' => Stardog::Format::N_TRIPLES })
        .to_return(status: 200)
    end

    it 'returns true' do
      expect(transaction.remove(data, Stardog::Format::N_TRIPLES)).to eq(true)
    end
  end

  describe '#clear' do
    before do
      stub_request(:post, %r{/#{name}/transaction/begin})
        .to_return(body: txid)

      transaction.start

      stub_request(:post, %r{/#{name}/#{txid}/clear})
        .to_return(status: 200)
    end

    it 'returns true' do
      expect(transaction.clear).to eq(true)
    end
  end
end
