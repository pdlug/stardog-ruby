require 'rubygems'
require 'bundler/setup'
Bundler.setup(:default, :development, :test)

require 'rspec/core'
require 'randexp'

require 'webmock/rspec'
include WebMock::API
WebMock.disable_net_connect!

$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'stardog'