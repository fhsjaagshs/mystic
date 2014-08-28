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
			raise EnvironmentError, "Environment '#{@env}' doesn't exist." unless db_yml.member? @env
      
      conf = db_yml[@env].symbolize
      conf[:dbname] = conf.delete :database
      raise MysticError, "Mystic only supports Postgres." unless /^postg.+$/i =~ conf[:adapter]
      
      @postgres = Postgres.new(conf)
      
      @env
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
			postgres.execute sql.sql_terminate.densify
		end

		def escape str=""
		#	raise ConnectionError, "Not connected to Postgres" unless postgres.connected?
			postgres.escape str
    end
    
    alias_method :sanitize, :escape

		def create_mig_table
			execute "CREATE TABLE IF NOT EXISTS mystic_migrations (mig_number integer, filename text)"
		end
	
		#
		# Command line
		#
		
		# Runs every yet-to-be-ran migration
		def migrate
			create_mig_table
			migrated_filenames = execute("SELECT filename FROM mystic_migrations").map{ |r| r["filename"] }
			mp = root.join("mystic","migrations").to_s
		
			Dir.entries(mp)
				.reject { |e| MIG_REGEX.match(e).nil? }
				.reject { |e| migrated_filenames.include? e }
				.sort { |a,b| MIG_REGEX.match(a)[:num].to_i <=> MIG_REGEX.match(b)[:num].to_i }
				.each { |fname|
					load File.join mp,fname
				
					mig_num,mig_name = MIG_REGEX.match(fname).captures
					Object.const_get(mig_name).new.migrate
					execute "INSERT INTO mystic_migrations (mig_number, filename) VALUES (#{mig_num},'#{fname}')"
				}
		end
	
		# Rolls back a single migration
		def rollback
			create_mig_table
			fname = execute("SELECT filename FROM mystic_migrations ORDER BY mig_number DESC LIMIT 1")[0]["filename"] rescue nil
			return if fname.nil?

			load root.join("mystic","migrations",fname).to_s
		
			mig_num,mig_name = MIG_REGEX.match(fname).captures

			Object.const_get(mig_name).new.rollback
		
			execute "DELETE FROM mystic_migrations WHERE filename='#{fname}' and mig_number=#{mig_num}"
		end
	
	  # Creates a blank migration in mystic/migrations
		def create_migration name=""
			name.strip!
			raise CLIError, "Migration name must not be empty." if name.empty?
      name.capitalize_first!
    
			migs = root.join "mystic","migrations"

			num = migs.entries.map{ |e| MIG_REGEX.match(e.to_s)[:num].to_i rescue 0 }.max.to_i+1

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