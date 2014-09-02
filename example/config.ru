#!/usr/bin/env ruby

require "mystic"

class Subscribers
  include Mystic::Model
end

class App
  def call env
    [200, {}, [Subscribers.select.to_json]]
  end
end

run App.new