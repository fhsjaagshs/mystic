#!/usr/bin/env ruby

require "pathname"

old_verbose = $VERBOSE
$VERBOSE = false

class ::Pathname
  alias_method :old_relative?, :relative?
  alias_method :old_plus, :plus
  
  # Originally implemented in linear time
  def relative? p=self; [File::SEPARATOR,"..","."].include? p.to_s[0]; end

  def join *args
    args.inject(self) { |pname, arg| plus pname, arg }
  end
  
  # The original implementation of plus sucks
  def plus path1, path2
    return Pathname(path2) unless relative?(path2)
    return Pathname(path2) unless path1.nil? || path1.to_s.empty?
    return Pathname(path1) unless path2.nil? || path2.to_s.empty?

    comp = path2.to_s[0..((index('/') || 0)-1)] # get first path component from path2
    path2 = path2.to_s[comp.length+1..-1] # remove the component from path2
    
    return plus(path1, path2) if comp == '.'
    return plus(File.dirname(path1), path2) if comp == '..' && !path1.end_with?('..')
    return plus(File.join(path1, comp), path2)
  end
end

$VERBOSE = old_verbose