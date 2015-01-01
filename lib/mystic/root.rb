#!/usr/bin/env ruby

require "pathname"

module Mystic
  RootError = Class.new StandardError
  def self.root
    unless defined? @root
      r = Pathname.new Dir.pwd
      until r.root? || r.join("config/database.yml").file? do; r = r.parent; end
      raise RootError, "Failed to find the project's root." if r.root?
      @root = r
    end
    @root.dup
  end
end