#!/usr/bin/env ruby

require "pg"
require "access_stack"

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
			:options,
			:tty,
			:sslmode,
			:krbsrvname,
			:gsslib
		].freeze
    
		INDEX_TYPES = [
      :btree,
			:hash,
			:gist,
			:spgist,
			:gin
		].freeze

    def initialize opts={}
      return if opts.empty?
			@pool = AccessStack.new(
				:size => opts[:pool] || 5,
				:timeout => opts[:timeout] || 30,
				:expires => opts[:expires],
				:create => lambda { create_pg opts.dup },
        :destroy => lambda { |pg| pg.close },
        :validate => lambda { |pg| pg != nil && pg.status == CONNECTION_OK }
			)
      @connected = true
    end
    
    alias_method :connect, :initialize
    
    def pool_size= v
      @pool.size = v
    end

    def disconnect
      @connected = false
			@pool.empty!
    end
    
    def reap!
    	@pool.reap!
    end
    
    def connected?
      @pool.reap!
      [!@pool.empty?, @connected].any?
    end
    
    def escape str
      @pool.with { |pg| pg.escape_string str }
    end
    
    def execute sql
			res = @pool.with { |pg| pg.exec sql }
			v = res[0][Mystic::JSON_COL] if res.ntuples == 1 && res.nfields == 1
			v ||= res.ntuples.times.map { |i| res[i] } unless res.nil?
			v ||= []
			v
    end
    
    def create_pg opts
      pg = PG.connect opts.subhash(*CONNECT_FIELDS)
      pg.set_notice_receiver { |r| }
      pg
    end
  end
end
