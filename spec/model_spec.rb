#!/usr/bin/env ruby

require "./spec_helper"

describe Mystic::Model do
  before :all do
    class SingletonModel
      include Mystic::Model
      column :id
    end
    
    class SimpleModel
      include Mystic::Model
      column :id
      column :name
      column :email
    end
    
    class ComplexModel
      include Mystic::Model
      column :id
      pseudocolumn :foobar, "row_to_json()"
    end
  end
  
  context "When generating column strings" do
    it "processes a model with one column" do
      expect(SingletonModel.column_string).to eq("id")
    end
    
    it "processes a model with many columns" do
      expect(SingletonModel.column_string).to eq("id,name,email")
    end
    
    it "generates a column string with multiple columns" do
      
    end
    
    it "generates a column string for "
  end
  
  describe "column string generation" do
    it "generates a column string for one column" do
      expect(SingletonModel.column_string).to eq("foobar")
    end
    
    it "generates a column string with multiple columns" do
      
    end
    
    it "generates a column string for "
  end
end