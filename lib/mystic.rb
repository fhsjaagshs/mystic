#!/usr/bin/env ruby

require "yaml"
require "erb"
require "pathname"
require "densify"
require_relative "./mystic/extensions.rb"
require_relative "./mystic/sql.rb"
require_relative "./mystic/postgres.rb"
require_relative "./mystic/migration.rb"
require_relative "./mystic/model.rb"

module Mystic
	MysticError = Class.new StandardError
  SQLError = Class.new StandardError
	RootError = Class.new StandardError
	EnvironmentError = Class.new StandardError
	AdapterError = Class.new StandardError
  ConnectionError = Class.new StandardError
	CLIError = Class.new StandardError
	MIG_REGEX = /^(?<num>\d+)_(?<name>[a-zA-Z]+)\.rb$/ # example: 1_MigrationClassName.rb
	JSON_COL = "mystic_return_json89788"
  
	class << self
    attr_reader :postgres
    
    #
    ## Accessors
    #
    
    def db_yml
      if @db_yml.nil?
        # Heroku uses ERB cuz rails uses it errwhere
        yaml = ERB.new(root.join("config","database.yml").read).result
  			@db_yml = YAML.load yaml
      end
      @db_yml
    end
    
    def env
      @env
    end
    
    def env= new_env
      @postgres.disconnect unless @postgres.nil?
      @postgres = nil
      
      load_env
      
			@env = (new_env || ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "development").to_s
			raise EnvironmentError, "Environment '#{@env}' doesn't exist." unless db_yml.key? @env
      
      conf = db_yml[@env].symbolize
      conf[:dbname] = conf.delete :database
      conf[:user] = conf.delete :username
      raise MysticError, "Mystic only supports Postgres." unless /^postg.+$/i =~ conf[:adapter]
      
      @postgres = Postgres.new conf
      
      @env
    end
    
    def manual_conn conf={}
      load_env
      @env = (ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "development").to_s
      @postgres = Postgres.new(conf)
    end
    
		def root path=Pathname.new(Dir.pwd)
			raise RootError, "Failed to find the application's root." if path == path.parent
			mystic_path = path.join "config", "database.yml"
      return root(path.parent) unless mystic_path.file? # exist? is implicit with file?
			path
		end
		
    #
    ## DB functionality
    #
    
		alias_method  :connect, :env=

		def disconnect
      postgres.disconnect
		end

		def execute sql=""
      #raise ConnectionError, "Not connected to Postgres" unless postgres.connected?
			postgres.execute sql.terminate.densify
		end

		def escape str=""
		#	raise ConnectionError, "Not connected to Postgres" unless postgres.connected?
			postgres.escape str
    end
    
    alias_method :sanitize, :escape

		def create_mig_table
			execute "CREATE TABLE IF NOT EXISTS mmigs (num integer, name text)"
		end
	
		#
		# Command line
		#
		
		# Runs every yet-to-be-ran migration
    def migrate
      create_mig_table
      last_mig_num = execute("SELECT max(num) FROM mmigs")[0]["max"] rescue 0
      
      migs = {}
      mp = root.join("mystic","migrations")
      Dir.entries(mp.to_s).each { |fname|
        m = MIG_REGEX.match(fname)
        next if m.nil?
        next if m[:num].to_i <= last_mig_num
        load mp.join(fname).to_s
        migs[m[:num].to_i] = m[:name]
      }
      
      migs.keys.sort { |a,b| a <=> b }.each do |num|
        name = migs[num]
				Object.const_get(name).new.migrate
				execute "INSERT INTO mmigs (num, name) VALUES (#{num},'#{name}')"
      end
    end
    
    # Rolls back a single migration
    def rollback
      create_mig_table
      res = execute("WITH max AS (SELECT max(num) FROM mmigs) SELECT max.max as num,mmigs.name FROM max,mmigs WHERE mmigs.num = max.max;").first
      return if res.nil?
      
      load root.join("mystic","migrations","#{res["num"]}_#{res["name"]}.rb")
      Object.const_get(res["name"]).new.rollback
      execute "DELETE FROM mmigs WHERE num=#{res["num"]}"
    end
	
	  # Creates a blank migration in mystic/migrations
		def create_migration name=""
			name.strip!
      name[0] = name[0].upcase
      
			raise ArgumentError, "Migration name must not be empty." if name.empty?
    
			migs = root.join "mystic","migrations"
			num = migs.entries.map { |e| MIG_REGEX.match(e.to_s)[:num].to_i rescue 0 }.max.to_i+1

			File.open(migs.join("#{num}_#{name}.rb").to_s, 'w') { |f| f.write(template name) }
		end
	
		private
    
		# Loads the .env file
		def load_env
      begin
			  root.join(".env").read.split("\n").map { |l| l.strip.split "=", 2 }.each { |k,v| ENV[k] = v }
      rescue
        nil
      end
		end

		# Retuns a blank migration's code in a String
		def template name
			raise ArgumentError, "Migrations must have a name." if name.nil?
			<<-RUBY
#!/usr/bin/env ruby

require "mystic"

class #{name} < Mystic::Migration
  def up
		
  end
  
  def down
		
  end
end
			RUBY
		end
	end
end