# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
Bundler.setup(:default, :development, :test)

require 'randexp'
require 'rspec/core'
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require 'webmock/rspec'
include WebMock::API
WebMock.disable_net_connect!

$LOAD_PATH.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'stardog'
