#
# examples/load_data.rb - 
#

require 'bundler/setup'

$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'stardog'

db = Stardog::Database.new(
  url: 'http://127.0.0.1:5822',
  name: 'rubytest',
  username: 'admin',
  password: 'admin'
)

rdf_data = File.read(File.expand_path('./test.turtle', File.dirname(__FILE__)))

tx = db.transaction do
  add(rdf_data, Stardog::Format::TURTLE)
  commit
end