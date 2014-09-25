#!/usr/bin/env ruby

require "pathname"

module Mystic
  RootError = StandardError.with_message "Could not find the project's root."
  def self.root
    if @root.nil?
      r = Pathname.new Dir.pwd
      
      until r.join("config", "database.yml").file? do # exist? is implicit with file?
        raise RootError if r.root?
        r = r.parent
      end

      @root = r
    end
    @root.dup
  end
end