#
# examples/query.rb - examples of querying Stardog
#
require 'bundler/setup'

$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'stardog'

db = Stardog::Server.new(url: 'http://127.0.0.1:5822')
  .db('rubytest', username: 'admin', password: 'admin')

puts "Which distinct subjects are in our database?"
db.query('SELECT DISTINCT ?s WHERE { ?s ?p ?o } LIMIT 10').each do |result|
  puts result[:s]
end

puts "\nWho created Stardog?"

solutions = db.query(%Q{
  PREFIX dc: <http://purl.org/dc/elements/1.1/>

  SELECT ?name
  WHERE { 
    <http://stardog.com/> dc:creator ?creator .
    ?creator dc:title ?name .
  }
})

puts solutions.first[:name]
