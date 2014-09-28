#!/usr/bin/env ruby

require_relative "./database"

module Mystic
  module CommandLine
    MPATH = Mystic.root.join "mystic","migrations"
    MREGEX = /^(?<num>\d+)_(?<name>[a-zA-Z]+)\.rb$/ # example: 1_MigrationClassName.rb
    #CLIError = Class.new StandardError
    class << self
  		def create_mig_table
  			execute "CREATE TABLE IF NOT EXISTS mmigs (num integer, name text)"
  		end

  		# Runs every yet-to-be-ran migration
      def migrate
        create_mig_table
        last_mig_num = execute("SELECT max(num) FROM mmigs")[0]["max"] rescue 0
      
        Dir.entries(MPATH.to_s).each_with_object({}) { |fna,migs|
          m = MREGEX.match(fn)
          next if m.nil? || m[:num].to_i <= last_mig_num
          load MPATH.join(fn).to_s
          migs[m[:num].to_i] = m[:name]
        }.sort { |a,b| a[0] <=> b[0] }.each { |num, name|
  				Object.const_get(name).new.migrate
  				execute "INSERT INTO mmigs (num,name) VALUES (#{num.to_s.escape},'#{name.sqlize}')"
        }
      end
    
      # Rolls back a single migration
      def rollback
        create_mig_table
        res = execute("WITH max AS (SELECT max(num) FROM mmigs) SELECT max.max as num,mmigs.name FROM max,mmigs WHERE mmigs.num=max.max;").first

        unless res.nil?
          load root.join("mystic","migrations","#{res["num"].escape}_#{res["name"]}.rb")
          Object.const_get(res["name"]).new.rollback
          execute "DELETE FROM mmigs WHERE num=#{res["num"].sqlize}"
        end
      end
	
  	  # Creates a blank migration in mystic/migrations
  		def create_migration name=""
  			num = MPATH.entries.map { |e| MREGEX.match(e.to_s)[:num].to_i rescue 0 }.max.to_i+1
        File.write MPATH.join("#{num}_#{_name}.rb"), template(name.strip.capitalize.gsub(" ",""))
  		end
      
  		# Retuns a blank migration's code in a String
  		def template name=""
  			raise ArgumentError, "Migrations must have a name." if name.nil? || name.empty?
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
end