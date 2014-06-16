#!/usr/bin/env ruby

require "rspec"
require "mystic/access_stack"

def create_stack
	Mystic::AccessStack.new(
		:size => 10,
		:timeout => 3,
		:create => lambda {
			"THIS"
		},
		:destroy => lambda { |instance|
			instance = nil
		},
		:validate => lambda { |instance|
			instance.is_a? String && instance.length > 0
		}
	)
end

describe Mystic::AccessStack do
	
	it "should create objects" do
		stack = create_stack
		res = stack.with{ |inst| inst + "FOOBAR" } 
		puts res
		stack.empty
		res == "THISFOOBAR"
	end
	
	it "should work concurrently" do
		stack = create_stack
		stack.create_objects 1
		
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
		rescue StandardError => e
			puts e.message
			return false
		end
		
		stack.count == 3
	end

end