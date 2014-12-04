require 'bundler/setup'
Bundler.setup

require_relative "../lib/mystic.rb"

RSpec.configure do |config|
	config.color = true
  
  config.before :all do
    Mystic.manual_conn
  end
end
