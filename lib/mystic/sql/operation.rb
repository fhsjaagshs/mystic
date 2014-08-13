#!/usr/bin/env ruby

module Mystic
  module SQL
    class Operation < SQLObject
			attr_reader :kind, :callback
			
      def initialize kind, opts={}
				@kind = kind
				@opts = opts.dup
				@callback = @opts.delete :callback
      end
      
      def method_missing meth, *args, &block
				@opts[meth.to_s.to_sym] rescue nil
      end
			
			def self.method_missing meth, *args, &block
				new meth, (args[0] || {})
			end
    end
  end
end