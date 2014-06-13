#!/usr/bin/env ruby

require "yaml"
require "pathname"
require "irb"
require "mystic/extensions"
require "mystic/sql"
require "mystic/adapter"
require "mystic/migration"
require "mystic/model"
require "mystic/access_stack"

module Mystic
	MysticError = Class.new StandardError
	RootError = Class.new StandardError
	EnvironmentError = Class.new StandardError
	AdapterError = Class.new StandardError
	CLIError = Class.new StandardError
	MIG_REGEX = /(?<num>\d+)_(?<name>[a-z]+)\.rb$/i # matches migration files (ex '1_MigrationClassName.rb')
	
	@@adapter = nil
	
	def self.adapter
		@@adapter
	end
  
  # Mystic.connect
  #   Connects to a database. It's recommended you use it like ActiveRecord::Base.establish_connection
  # Arguments:
  #   env - The env from database.yml you wish to use
	def self.connect(env="")
		@@env = env.to_s
		path = root.join("config","database.yml").to_s
		db_yml = YAML.load_file path
		
		raise EnvironmentError, "Environment doesn't exist." unless db_yml.member? @@env
		
		conf = db_yml[@@env]
		conf["dbname"] = conf.delete "database"
		
		create_adapter(
			:adapter => conf.delete("adapter"),
			:poolsize => conf["pool"],
			:timeout => conf["timeout"]
		)
		
		@@adapter.connect conf
	end
	
  # Mystic.disconnect
  #   Disconnects from the connected database. Use it like ActiveRecord::Base.connection.disconnect!
	def self.disconnect
		@@adapter.disconnect
		@@adapter = nil
		true
	end

  # Mystic.execute
  #   Execute some sql. It will be densified (the densify gem) and sent to the DB
  # Arguments:
  #   sql - The SQL to execute
  # Returns: Native Ruby objects representing the response from the DB (Usually an Array of Hashes)
  def self.execute(sql="")
		raise AdapterError, "Adapter is nil, so Mystic is not connected." if @@adapter.nil?
    @@adapter.execute sql
  end
  
  # Mystic.sanitize
  #   Escape a string so that it can be used safely as input. Mystic does not support statement preparation, so this is a must.
  # Arguments:
  #   str - The string to sanitize
  # Returns: the sanitized string
  def self.sanitize(str="")
		raise AdapterError, "Adapter is nil, so Mystic is not connected." if @@adapter.nil?
    @@adapter.sanitize str
  end
	
	# Mystic.root
	#   Get the app root
	# Aguments:
	#   To be ignored
	# Returns:
	#   A pathname to the application's root
  def self.root(path=Pathname.new(Dir.pwd))
		raise RootError, "Failed to find the application's root." if path == path.parent
		mystic_path = path.join "config", "database.yml"
		return path if mystic_path.file? # exist? is implicit with file?
		root path.parent
  end
	
	# Mystic.create_table
	#   Create migration tracking table
	def self.create_table
		execute "CREATE TABLE IF NOT EXISTS mystic_migrations (mig_number integer, filename text)"
	end
	
	#
	# Command line
	#
	
	def self.console
		require "mystic"
		puts "Starting Mystic console"
		IRB.setup nil
		IRB.conf[:IRB_NAME] = "mystic"
		IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
		require 'irb/ext/multi-irb'
		IRB.irb nil, IRB::WorkSpace.new
		nil
	end
	
  # Runs every yet-to-be-ran migration
	def self.migrate
		create_table
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
	def self.rollback
		create_table
		fname = execute("SELECT filename FROM mystic_migrations ORDER BY mig_number DESC LIMIT 1")[0]["filename"] rescue nil
		return if fname.nil?

	  load root.join("mystic","migrations",fname).to_s
		
		mig_num,mig_name = MIG_REGEX.match(fname).captures

	  Object.const_get(mig_name).new.rollback
		
	  execute "DELETE FROM mystic_migrations WHERE filename='#{fname}' and mig_number=#{mig_num}"
	end
	
  # Creates a blank migration in mystic/migrations
	def self.create_migration(name="")
		name.strip!
		raise CLIError, "Migration name must not be empty." if name.empty?
		
		name[0] = name[0].capitalize
    
		migs = root.join "mystic","migrations"

		num = migs.entries.map { |e| MIG_REGEX.match(e.to_s)[:num].to_i rescue 0 }.max.to_i+1

		File.open(migs.join("#{mig_num}_#{name}.rb").to_s, 'w') { |f| f.write(template name) }
	end
	
  # Retuns a blank migration's code in a String
	def self.template(name=nil)
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
	
	#
	# Private helpers
	#
	
	def self.create_adapter(opts={})
		name = opts[:adapter].to_s.downcase.strip
		name = "postgres" if name =~ /^postg.*$/i # Includes PostGIS
		name = "mysql" if name =~ /^mysql.*$/i
		
		require "mystic/adapters/" + name
		
		@@adapter = Object.const_get("Mystic::#{name.capitalize}Adapter").new
		@@adapter.pool_size = opts[:pool_size].to_i
		@@adapter.pool_timeout = opts[:timeout].to_i
	end
end