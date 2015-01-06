#!/usr/bin/env ruby

require "yaml"
require "erb"
require "securerandom"

module Mystic
  singleton_class.class_eval do
    def config
      @config
    end
    
    def config= c
      if c.nil?
        @config = Mystic::Configuration.new
      else
        @config = c
      end
    end
  end
  
  class Configuration
    URL_FIELDS = [:user, :password, :host, :hostaddr, :port, :dbname].freeze
  	POSTGRES_FIELDS = [:host, :hostaddr, :port, :dbname, :user, :password, :connect_timeout, :client_encoding, :options, :sslmode].freeze
    
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
      :reaping_frequency, # frequency in seconds to periodically run the Reaper, which attempts to find and close dead connections, which can occur if a programmer forgets to close a connection at the end of a thread or a thread dies unexpectedly. (Default nil, which means don't run the Reaper).
      :dead_connection_timeout # number of seconds from last checkout after which the Reaper will consider a connection reapable. (default 5 seconds). 
    ].freeze
    
    def env
      ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "development"
    end
    
    def env= new_env
      raise EnvironmentError, "Environment '#{new_env}' doesn't exist." unless database.key? new_env
      unless new_env.to_s == env
        ENV["RACK_ENV"] = new_env.to_s
        Mystic.connect if Mystic.connected?
      end
      env
    end
    
    # The column used by Mystic::Model to return JSON
    def json_column
      "json_#{SecureRandom.uuid}".freeze
    end
    
    def database
      unless defined? @database
        # Heroku uses ERB cuz rails uses it errwhere
        @db_ybl = YAML.load(ERB.new(Mystic.root.join("config","database.yml").read).result)
                    .symbolize
                    .reject { |k,v| v[:adapter].match(/postg.*/).nil? }
                    .subhash(*(POOL_FIELDS+DATABASE_FIELDS))
      end
      @database
    end
    
    def postgres
      unless defined? @configs
        @configs = Hash[database.map { |env,hash|
          # :database as connection string
          if hash[:database].index "="
            hash.merge Hash[hash.delete(:database)
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
          hash[:fallback_application_name] = $0
          
          [env, hash.subhash(*POSTGRES_FIELDS)]
        }]
      end
      @configs[env]
    end
    
    def pool
      @pconfigs = Hash[database.map { |env, h| [env, h.subhash(*POOL_FIELDS)] }] unless defined? @pconfigs
      @pconfigs[env]
    end
    
    def database_url c=nil
      if c
        base_url = "#{c[:user]}:#{c[:password]}@#{c[:host]||c[:hostaddr]}:#{c[:port]}/#{c[:dbname]}"
        query_str = c
                    .reject { |k,v| POSTGRES_FIELDS.include? k }
                    .map { |k,v| "#{k.to_s}=#{v}" }
                    .join '&' 
                    # query_str contains whatever connection params are not in the base_url
        URI.escape "postgresql://#{base_url}?#{query_str}"
      else
        unless defined? @db_urls
          @db_urls = Hash[postgres.map { |env, conf| [env, database_url(conf)] }]
        end
        @db_urls
      end
    end
  end
  
  self.config = Mystic::Configuration.new
end