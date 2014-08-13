#!/usr/bin/env ruby

require "pg"

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

    def inititalize opts={}
			disconnect unless @pool.nil?
			@pool = AccessStack.new(
				:size => opts[:pool_size],
				:timeout => opts[:timeout],
				:expires => opts[:expires],
				:create => lambda { PG.connect opts.subhash(*CONNECT_FIELDS)},
        :destroy => lambda { |pg| pg.close },
        :validate => lambda { |pg| pg != nil && pg.status == CONNECTION_OK }
			)
    end
    
    alias_method :connect, :initialize

    def disconnect
			@pool.empty!
    end
    
    def reap
    	@pool.reap
    end
    
    def connected?
      !@pool.empty?
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
  end
end
