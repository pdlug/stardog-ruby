$:.push File.expand_path("./lib", File.dirname(__FILE__))
require 'stardog/version'

Gem::Specification.new do |s|
  s.name              = 'stardog-ruby'
  s.version           = Stardog::VERSION
  s.date              = '2013-05-27'

  s.required_ruby_version = ">= 1.9.2"
  s.description       = "Ruby client for the Stardog RDF database"
  s.summary           = s.description
  s.authors           = ["Paul Dlug"]
  s.email             = "paul.dlug@gmail.com"
  s.homepage          = "http://github.com/pdlug/stardog-ruby"
  s.files             = %w( README.md Rakefile CHANGELOG.md ) + Dir["{doc,bin,lib,spec}/**/*"]
  #s.test_files        = s.files.select { |p| p =~ /^test\/.*_test.rb/ }
  #s.extra_rdoc_files  = s.files.select { |p| p =~ /^README/ } << 'LICENSE'
  #s.rdoc_options      = %w[--line-numbers --inline-source --title Sinatra --main README.rdoc --encoding=UTF-8]

  #s.files         = `git ls-files`.split("\n")
  #s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.require_paths      = ["lib"]

  s.add_dependency 'activesupport'
  s.add_dependency 'multi_json'
  s.add_dependency 'rdf'
  s.add_dependency 'rest-client'
  s.add_dependency 'sparql-client'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'randexp'
  s.add_development_dependency 'github-markup'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'yard'
end
