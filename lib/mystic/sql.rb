#!/usr/bin/env ruby

module Mystic
  module SQL
		Error = Class.new StandardError
  end
end

file_folder = File.dirname(File.absolute_path(__FILE__))
Dir.glob(file_folder + "/sql/**/*.rb", &method(:require))