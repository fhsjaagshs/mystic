#!/usr/bin/env ruby

require "yaml"
require "erb"
require "uri"
require "securerandom"

module Mystic
  singleton_class.class_eval do
    def config
      @config ||= Mystic::Configuration.new
    end
    
    def config= c
      @config = c || Mystic::Configuration.new
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
      raise ArgumentError, "Environment '#{new_env}' doesn't exist." unless database.key? new_env
      unless new_env == env
        ENV["RACK_ENV"] = ENV["RAILS_ENV"] = new_env.to_s
        Mystic.connect if Mystic.connected?
      end
      env
    end
    
    # The column used by Mystic::Model to return JSON
    def json_column
      "mystic_json_column".freeze
    end
    
    # loads database.yml or DATABASE_URL
    def raw
      if Mystic.root.join("config","database.yml").file? # also checks for existence
        Hash[YAML.load(ERB.new(Mystic.root.join("config","database.yml").read).result).map { |env,hsh| [env, hsh.symbolize.subhash(*(POOL_FIELDS+DATABASE_FIELDS))] }]
      else
        u = URI.parse ENV["DATABASE_URL"]
        h = { 
          "url" => {
            :host => u.host,
            :port => u.port,
            :username => u.user,
            :password => u.password,
            :database => u.path[1..-1]
          }
        }
        u.query.split('&').map { |p| p.split('=',2) }.each { |k,v| h["url"][k.to_sym] = v }
        h.subhash(*(POOL_FIELDS+DATABASE_FIELDS))
      end
    end
    
    # database config
    def database
      unless defined? @database_config
        @database_config ||= Hash[raw.map { |env,h|
                                    if h[:database].index '=' # :database as connection string
                                      h.merge Hash[h.delete(:database).split(' ').map { |s| s.split('=',2) }.map { |k,v| [k.to_s.strip.downcase.to_sym, v.index('\'').nil? ? v : v[1..-2] ] }]
                                    else
                                      h[:dbname] = h.delete :database
                                      h[:user] = h.delete :username
                                      h[:connect_timeout] = h.delete :timeout
                                      h[:client_encoding] = h.delete :encoding
                                      h[:fallback_application_name] ||= $0
                                      h
                                    end
                                    
                                    h[:host] ||= "localhost"
                                    h[:port] ||= 5432
                                    h[:user] ||= ENV["USER"] || ENV["USERNAME"]
                                    h[:client_encoding] ||= "utf8"
                                    
                                    [env, h.subhash(*POSTGRES_FIELDS)]
                                  }]
      end
      @database_config[env] || @database_config["url"]
    end
    
    def pool
      @pool_configs = Hash[raw.map { |env, h| [env, h.subhash(*POOL_FIELDS)] }] unless defined? @pool_configs
      @pool_configs[env] || @pool_configs["url"]
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
        @db_urls = Hash[database.map { |env, conf| [env, database_url(conf)] }] unless defined? @db_urls
        @db_urls[env] || @db_urls["url"]
      end
    end
  end
end