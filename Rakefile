require 'rubygems'
require 'bundler/setup'
Bundler.setup(:default, :development, :test)

require 'rubygems/package_task'
require 'rspec/core/rake_task'

gemspec = Gem::Specification.load('stardog-ruby.gemspec')

Gem::PackageTask.new(gemspec) do |pkg|
end

desc 'Default: run spec examples'
task default: :spec

desc "Run all examples (or a specific spec with TASK=xxxx)"
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/functional/**/*_spec.rb'
  t.rspec_opts = %w(-fs --color)
end

require 'rake/clean'
CLEAN.include('doc', 'pkg')

require 'yard'
require 'yard/rake/yardoc_task'
YARD::Rake::YardocTask.new do |t|
end
