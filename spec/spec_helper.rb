require 'bundler/setup'
Bundler.require :default, :test
require_relative '../main.rb'

set :environment, :test

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure { |c| c.include RSpecMixin }
