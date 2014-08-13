require 'bundler/setup'
Bundler.setup

require "./lib/mystic.rb"

RSpec.configure do |config|
	config.color = true
end
