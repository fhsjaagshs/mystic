#!/usr/bin/env ruby

require "./spec_helper"
require "lib/"

# IMPORTANT:
# To run this test, install Postgres.app and run it.

describe ::Pathname do
  before :all do
    @username = ENV['USER'] || ENV['USERNAME']
    @pg_alt = Mystic::Postgres.new :user => @username, :password => "", :dbname => @username, :port => 5432, :host => "localhost"
  end
  
  after :all do
    @pg_alt.disconnect!
  end
  
  it "executes a query & coerces types" do
    res = @pg_alt.execute("SELECT false::boolean as \"boolean\", 0::integer as \"integer\", 'I am a programmer'::text as \"text\", 5::money as \"money\" 3.141592654::numeric as \"float\";")
    
    expect(res["boolean"]).to be_kind_of(FalseClass)#[TrueClass, FalseClass]).to include(res["boolean"])
    expect(res["integer"]).to be_kind_of(Integer)
    expect(res["text"]).to be_kind_of(String)
    expect(res["money"]).to be_kind_of(Float)
    expect(res["numeric"]).to be_kind_of(Float)
  end
end