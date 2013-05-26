require File.dirname(__FILE__) + '/../spec_helper'

describe Stardog::Transaction do
  let(:url)         { %r{http://[:word:]\.(com|net|org)}.gen }
  let(:name)        { /[:word:]/.gen }
  let(:database)    { Stardog::Database.new(url: url, name: name, username: /[:word:]/.gen, password: /[:word:]/.gen) }
  let(:transaction) { Stardog::Transaction.new(database) }

  let(:txid) { /\d{10}/.gen }

  describe 'initialization' do
    it 'should accept a Database' do
      transaction.should_not be_nil
      transaction.database.should == database
    end
  end

  describe '#start' do
    before do
      stub_request(:post, %r{/transaction/begin}).
        to_return(body: txid)
      @retval = transaction.start
    end

    it 'should start a transaction on the server and set the ID to the one returned' do
      transaction.id.should == txid
    end

    it 'should return the transaction' do
      @retval.should == transaction
    end

    it 'should mark the transaction as started' do
      transaction.should be_started
    end
  end

  describe '#commit' do
    describe 'transaction not started' do
      it 'should raise an exception' do
        expect { transaction.commit }.to raise_error(Stardog::TransactionConflict)
      end
    end

    describe 'transaction started' do
      describe 'successful commit' do
        before do
          stub_request(:post, %r{/#{name}/transaction/begin}).
            to_return(body: txid)
          transaction.start

          stub_request(:post, %r{/transaction/commit/#{txid}})

          @retval = transaction.commit
        end

        it 'should return true' do
          @retval.should be_true
        end

        it 'should be committed' do
          transaction.should be_committed
        end
      end

      describe 'duplicate commit (or other conflict)' do
          before do
          stub_request(:post, %r{/#{name}/transaction/begin}).
            to_return(body: txid)
          transaction.start

          stub_request(:post, %r{/transaction/commit/#{txid}})
          transaction.commit

          stub_request(:post, %r{/transaction/commit/#{txid}}).
            to_return(status: 409)
        end

        it 'should return true' do
          expect { transaction.commit }.to raise_error(Stardog::TransactionConflict, /Conflict/)
        end

        it 'should be committed' do
          transaction.should be_committed
        end
      end
    end
  end

  describe '#rollback' do
    describe 'transaction not started' do
      it 'should raise an exception' do
        expect { transaction.rollback }.to raise_error(Stardog::TransactionConflict)
      end
    end

    describe 'transaction started' do
      describe 'successful rollback' do
        before do
          stub_request(:post, %r{/#{name}/transaction/begin}).
            to_return(body: txid)
          transaction.start

          stub_request(:post, %r{/transaction/rollback/#{txid}})

          @retval = transaction.rollback
        end

        it 'should return true' do
          @retval.should be_true
        end

        it 'should not be committed' do
          transaction.should_not be_committed
        end
      end

      describe 'duplicate rollback (or other conflict)' do
        before do
          stub_request(:post, %r{/#{name}/transaction/begin}).
            to_return(body: txid)
          transaction.start

          stub_request(:post, %r{/transaction/rollback/#{txid}})
          transaction.rollback

          stub_request(:post, %r{/transaction/rollback/#{txid}}).
            to_return(status: 409)
        end

        it 'should return true' do
          expect { transaction.rollback }.to raise_error(Stardog::TransactionConflict, /Conflict/)
        end

        it 'should not be committed' do
          transaction.should_not be_committed
        end
      end
    end
  end

  describe '#add' do
    let(:data) { '<http://www.stardog.com/> <http://purl.org/dc/elements/1.1/title> "Stardog" .' }

    before do
      stub_request(:post, %r{/#{name}/transaction/begin}).
        to_return(body: txid)

      transaction.start

      stub_request(:post, %r{/#{name}/#{txid}/add}).
        with(body: data, headers: {'Content-Type' => Stardog::Format::N_TRIPLES}).
        to_return(status: 200)
    end

    it 'should return true' do
      transaction.add(data, Stardog::Format::N_TRIPLES).should be_true
    end
  end

  describe '#remove' do
    let(:data) { '<http://stardog.com/> <http://purl.org/dc/elements/1.1/title> "Stardog" .' }

    before do
      stub_request(:post, %r{/#{name}/transaction/begin}).
        to_return(body: txid)

      transaction.start

      stub_request(:post, %r{/#{name}/#{txid}/remove}).
        with(body: data, headers: {'Content-Type' => Stardog::Format::N_TRIPLES}).
        to_return(status: 200)
    end

    it 'should return true' do
      transaction.remove(data, Stardog::Format::N_TRIPLES).should be_true
    end
  end

  describe '#clear' do
    before do
      stub_request(:post, %r{/#{name}/transaction/begin}).
        to_return(body: txid)

      transaction.start

      stub_request(:post, %r{/#{name}/#{txid}/clear}).
        to_return(status: 200)
    end

    it 'should return true' do
      transaction.clear.should be_true
    end
  end
end