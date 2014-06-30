#!/usr/bin/env ruby

require "yaml"
require "pathname"
require "mystic/extensions"
require "mystic/constants"
require "mystic/sql"
require "mystic/adapter"
require "mystic/migration"
require "mystic/model"

module Mystic	
	@@adapter = nil
	
	class << self
		def adapter
			@@adapter
		end
		
		# Mystic.connect
		#   Connects to a database. It's recommended you use it like ActiveRecord::Base.establish_connection
		# Arguments:
		#   env - The env from database.yml you wish to use
		def connect(env="")
			load_env
			@@env = (env || ENV["RACK_ENV"] || ENV["RAILS_ENV"] || "development").to_s
			path = root.join("config","database.yml").to_s
			db_yml = YAML.load_file path
		
			raise EnvironmentError, "Environment '#{@@env}' doesn't exist." unless db_yml.member? @@env
		
			conf = db_yml[@@env].symbolize
			conf[:dbname] = conf[:database]
			
			@@adapter = Adapter.create(
				conf[:adapter],
				:pool_size => conf[:pool_size].to_i,
				:pool_timeout => conf[:timeout].to_i,
				:pool_expires => conf[:expires].to_i
			)
		
			@@adapter.connect conf
			true
		end
	
		alias_method :env=, :connect
	
		def env
			@@env
		end
		
		# Mystic.disconnect
		#   Disconnects from the connected database. Use it like ActiveRecord::Base.connection.disconnect!
		def disconnect
			@@adapter.disconnect
			@@adapter = nil
			true
		end

		# Mystic.execute
		#   Execute some sql. It will be densified (the densify gem) and sent to the DB
		# Arguments:
		#   sql - The SQL to execute
		# Returns: Native Ruby objects representing the response from the DB (Usually an Array of Hashes)
		def execute(sql="")
			raise AdapterError, "Adapter is nil, so Mystic is not connected." if @@adapter.nil?
			@@adapter.execute sql.sql_terminate.densify
		end
  
		# Mystic.sanitize
		#   Escape a string so that it can be used safely as input. Mystic does not support statement preparation, so this is a must.
		# Arguments:
		#   str - The string to sanitize
		# Returns: the sanitized string
		def sanitize(str="")
			raise AdapterError, "Adapter is nil, so Mystic is not connected." if @@adapter.nil?
			@@adapter.sanitize str
		end
	
		# Mystic.root
		#   Get the app root
		# Aguments:
		#   To be ignored
		# Returns:
		#   A pathname to the application's root
		def root(path=Pathname.new(Dir.pwd))
			raise RootError, "Failed to find the application's root." if path == path.parent
			mystic_path = path.join "config", "database.yml"
			return path if mystic_path.file? # exist? is implicit with file?
			root path.parent
		end
	
		# TODO: Make this a migration
		# TODO: Silence this
		# Mystic.create_table
		#   Create migration tracking table
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
				.reject{ |e| MIG_REGEX.match(e).nil? }
				.reject{ |e| migrated_filenames.include? e }
				.sort{ |a,b| MIG_REGEX.match(a)[:num].to_i <=> MIG_REGEX.match(b)[:num].to_i }
				.each{ |fname|
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
		def create_migration(name="")
			name.strip!
			raise CLIError, "Migration name must not be empty." if name.empty?
		
			name[0] = name[0].capitalize
    
			migs = root.join "mystic","migrations"

			num = migs.entries.map{ |e| MIG_REGEX.match(e.to_s)[:num].to_i rescue 0 }.max.to_i+1

			File.open(migs.join("#{num}_#{name}.rb").to_s, 'w') { |f| f.write(template name) }
		end
	
		private
		
		# Loads the .env file
		def load_env
			root.join(".env").read
											 .split("\n")
											 .map { |l| l.strip.split "=", 2 }
											 .each { |k,v| ENV[k] = v }
		end
			
		# Retuns a blank migration's code in a String
		def template(name=nil)
			raise ArgumentError, "Migrations must have a name." if name.nil?
			<<-mig_template
#!/usr/bin/env ruby

require "mystic"

class #{name} < Mystic::Migration
  def up
		
  end
  
  def down
		
  end
end
			mig_template
		end
	end
end