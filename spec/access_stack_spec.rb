#!/usr/bin/env ruby

require "rspec"
require "mystic"

def create_stack
	Mystic::AccessStack.new(
		:size => 10,
		:timeout => 3,
		:create => lambda {
			"THIS"
		},
		:destroy => lambda { |instance|
			instance = nil
		}
	)
end

describe Mystic::AccessStack do
	
	it "should create objects" do
		stack = create_stack
		res = stack.with{ |inst| inst + "FOOBAR" } || "THISFOOBAR"
		stack.empty
		res
	end
	
	it "should work concurrently" do
		stack = create_stack
		stack.create 1
		
		begin
			t = []
			
			t << Thread.new {
				puts stack.with{ |inst| inst + "ONE" }
			}
		
			t << Thread.new {
				puts stack.with{ |inst| inst + "TWO" }
			}
		
			t << Thread.new {
				puts stack.with{ |inst| inst + "Three" }
			}
			
			t.each(&:join)
		rescue StandardError
			return false
		end
		
		stack.count == 3
	end

end