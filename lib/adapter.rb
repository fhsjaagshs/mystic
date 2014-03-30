#!/usr/bin/env ruby

class Adapter
  
  def size_hash
    {}
  end
  
  def column(type)
    ""
  end
  
  def max_length_for(type_symbol)
    return size_hash[type_symbol]  
  end
end