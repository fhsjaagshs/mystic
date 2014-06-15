#!/usr/bin/env ruby

require "rspec"
#require File.expand_path("../lib/mystic.rb")
require "mystic"

describe Mystic::AccessStack do
	
	it "Should create objects" do
		
		stack = Mystic::AccessStack.new(
			:size => 10,
			:timeout => 3,
			:create => lambda {
				""
			},
			:destroy => lambda { |instance|
				instance = ""
			}
		)
		
		res = stack.with{ |inst| inst + "FOOBAR" } || "FOOBAR"
		stack.shutdown
		res
	end

end