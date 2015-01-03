#!/usr/bin/env ruby

require "./spec_helper"

describe "Mystic helpers" do
  context Object do
    it "sqlizes an object" do
      class Stringish
        def to_str
          "string representation"
        end
      end
      
      dt = DateTime.now
      d = Date.now
      t = Time.now
      s = Stringish.new
      
      # TODO: represent what each expression should equal in an absolute way
      expect(nil.sqlize).to eq("NULL")
      expect(s.sqlize).to eq(s.to_str)
      expect("asdf".sqlize).to eq("asdf".quote)
      expect(:asdf.sqlize).to eq(:asdf.to_s.dblquote)
      expect(1.sqlize).to eq(1.to_s.escape)
      expect(dt.sqlize).to eq(dt.to_s.quote)
      expect(d.sqlize).to eq(d.to)s.quote)
      expect(t.sqlize).to eq(t.to_s.quote)
    end
  end
  
  context String do
    it "can determine if it's numeric" do
      expect("1".numeric?).to be_true
      expect("asf".numeric?).to be_false
    end
    
    it "terminates an SQL query" do
      t = ';'
      unterminated = "asdf"
      terminated = unterminated + t
      
      expect(terminated.terminate(t)).to eq(terminated)
      expect(unterminated.terminate(t)).to eq(unterminated+t)
    end
  end
  
  context Array do
    # Array#unify_args
    it "processes custom arguments" do
      pending "implement"
    end
    
    it "turns its elements into symbols" do
      ary = ["asdf", 1]
      symbolized = ary.symbolize

      expect(symbolized[0]).to eq(ary[0].to_s.to_sym)
      expect(symbolized[1]).to eq(ary[1].to_s.to_sym)
      
      ary.symbolize!
      expect(ary).to eq(symbolized)
    end
  end
end