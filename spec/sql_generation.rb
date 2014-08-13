#!/usr/bin/env ruby

describe Mystic do
  before :all do
    
  end
  
  context "When generating SQL" do
    it "generates columns" do
      
    end
    
    it "generates tables" do
      
    end
    
    it "generates indeces" do
      
    end
  end
  
  context "When migrating" do
    # TODO: IMPLEMENT THIS
    it "works" do
      class Mig < Mystic::Migration
        def up
          
        end
        
        def down
          
        end
      end
      
      expect(Mig.new.to_sql(:up)).to_not be_nil
      expect(Mig.new.to_sql(:down)).to_not be_nil
    end
  end
end