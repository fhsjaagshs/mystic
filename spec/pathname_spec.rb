#!/usr/bin/env ruby

require "./spec_helper"

describe ::Pathname do
  before :all do
    require "mystic/pathname"
    def plus path1, path2 # -> path
      (Pathname.new(path1) + Pathname.new(path2)).to_s
    end
  end
  
  it "adds paths" do
    # expected behavior
    expect(plus "/", "/").to eq("/")
    expect(plus "a", "b").to eq("a/b")
    expect(plus "a", ".").to eq("a")
    expect(plus ".", "b").to eq("b")
    expect(plus ".", ".").to eq(".")
    expect(plus "a", "/b").to eq("a/b")
    
    expect(plus "/","..").to eq("/")
    expect(plus "a", "..").to eq(".")
    expect(plus "a/b", "..").to eq("a")
    expect(plus "..", "..").to eq("../..")
    expect(plus "/", "../c").to eq("/c")
    expect(plus "a", "../c").to eq("c")
    expect(plus "a/b", "../c").to eq("a/c")
    expect(plus "..", "../c").to eq("../../c")
    
    expect(plus "a//b/c", "../d//e").to eq("a/b/d/e")
  end
end