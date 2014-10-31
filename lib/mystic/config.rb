#!/usr/bin/env ruby

require "yaml"
require "erb"

module Mystic
  VALID_ADAPTERS = [
    "postgres",
    "postgis"
  ].freeze
  
  ## ActiveRecord database.yml fields
  DATABASE_FIELDS = [
    :host, # Defaults to a Unix-domain socket in /tmp. On machines without Unix-domain sockets, the default is localhost.
    :port, # Defaults to 5432.
    :username, # Defaults to be the same as the operating system name of the user running the application.
    :password, # Password to be used if the server demands password authentication.
    :database, # Defaults to be the same as username.
    :encoding, # Optional client encoding. Passed as client_encoding in the Mystic::Postgres connect ags (the same as pg's connect args)
    :min_messages, # An optional client min messages that is used in a SET client_min_messages TO <min_messages> call on the connection.
    :variables, # An optional hash of additional parameters that will be used in SET SESSION key = val calls on the connection.
    :insert_returning # An optional boolean to control the use or RETURNING for INSERT statements defaults to true.  
  ].freeze
  
  POOL_FIELDS = [
    :pool, # (number) Size of connection pool (default 5)
    :checkout_timeout, # (number) How many seconds to block and wait for a connection before giving up and raising a timeout error (default 5 seconds).
    :reaping_frequency # frequency in seconds to periodically run the Reaper, which attempts to find and close dead connections, which can occur if a programmer forgets to close a connection at the end of a thread or a thread dies unexpectedly. (Default nil, which means don't run the Reaper).
    :dead_connection_timeout # number of seconds from last checkout after which the Reaper will consider a connection reapable. (default 5 seconds). 
  ]
  
  class << self
    def db_yml
      if @db_yml.nil?
        # Heroku uses ERB cuz rails uses it errwhere
        @db_ybl = YAML.load(ERB.new(root.join("config","database.yml").read).result)
                    .symbolize
                    .reject { |k,v| v[:adapter].match(/postg.*/).nil? }
                    .subhash(*(POOL_FIELDS+DATABASE_FIELDS))
      end
      @db_yml
    end
    
    # Postgres connect params, precalculated
    def config
      if @configs.nil?
        @configs = Hash[db_yml.map { |env,hash|
          # :database as connection string
          if hash[:database].index "="
            hash.merge Hash[hash[:database]
                              .split(' ')
                              .map { |s| s.split('=',2) }
                              .map { |k,v| [k.to_s.strip.downcase.to_sym, v.index("'").nil? ? v : v[1..-1] ] }
                            ]
          end
          
          hash.delete :insert_returning # This is already implemented elsewhere with more functionality
          hash.delete :min_messages # TODO: Implement this
          hash.delete :variables # TODO: Implement this
          hash[:dbname] = hash.delete :database
          hash[:user] = hash.delete :username
          hash[:connect_timeout] = hash.delete :timeout
          hash[:client_encoding] = hash.delete :encoding
          
          [env, hash.subhash(*Mystic::Postgres::CONNECT_FIELDS)]
        }]
      end
      @configs[env]
    end
    
    def pool_config
      if @pconfigs.nil?
        @pconfigs = Hash[db_yml.map { |env, h| [env, h.subhash(*Mystic::POOL_FIELDS)] }]
      end
      @pconfigs[env]
    end
    
    def database_url
      conf = db_yml[env]
      opts = conf.reject { |k,v| [:user, :password, :host, :hostaddr, :port, :dbname].include? k }
      URI.escape "postgresql://#{conf[:user]}:#{conf[:password]}@#{conf[:host] || conf[:hostaddr]}:#{conf[:port]}/#{conf[:dbname]}?#{opts.map { |k,v| "#{k.to_s}=#{v}" }*'&'}"
    end
  end
end