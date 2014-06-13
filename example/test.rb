#!/usr/bin/env ruby

require "pathname"

p = Pathname.new "/Users/nathaniel/"

t = Time.now
r = Mystic.root
puts "#{'%.2f' % ((Time.now-t).to_f*1000)}ms"
t = Time.now
Mystic.sanitize("asdf")
puts "#{'%.2f' % ((Time.now-t).to_f*1000)}ms"