#!/usr/bin/env ruby

require "pathname"

module Mystic
  RootError = StandardError.with_message "Could not find the project's root."
  def self.root
    unless defined? @root
      r = Pathname.new Dir.pwd
      until (r.root? || r.join("config/database.yml").file?) do; r = r.parent; end
      raise RootError if r.root?
      @root = r
    end
    @root.dup
  end
end