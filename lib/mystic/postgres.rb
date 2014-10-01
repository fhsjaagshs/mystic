#!/usr/bin/env ruby

require_relative "../../ext/mystic/postgres_ext"

module Mystic
  class Postgres
  	CONNECT_FIELDS = [
  		:host,
  		:hostaddr,
  		:port,
  		:dbname,
  		:user,
  		:password,
  		:connect_timeout,
      :client_encoding,
  		:options,
  		:sslmode
  	].freeze
    
    attr_reader :options, :error
    attr_accessor :special_field
    
    def self.connect hash={}
      new hash
    end
    
    def connstr hash={}
      hash
        .select { |k,v| CONNECT_FIELDS.include?(k.to_s.downcase.to_sym) }
        .map { |k,v| "#{k.to_s.downcase}='#{v.to_s.gsub(/[\\']/, &'\\'.method(:+))}'" } * ' '
    end
  end
end