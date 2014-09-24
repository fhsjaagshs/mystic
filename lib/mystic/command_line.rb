#!/usr/bin/env ruby

module Mystic
  module CommandLine
    class << self
  		def create_mig_table
  			execute "CREATE TABLE IF NOT EXISTS mmigs (num integer, name text)"
  		end

  		# Runs every yet-to-be-ran migration
      def migrate
        create_mig_table
        last_mig_num = execute("SELECT max(num) FROM mmigs")[0]["max"] rescue 0
      
        mp = root.join "mystic", "migrations"
        
        Dir.entries(mp.to_s).each_with_object({}) { |fname,migs|
          m = MIG_REGEX.match(fname)
          next if m.nil? || m[:num].to_i <= last_mig_num
          load mp.join(fname).to_s
          migs[m[:num].to_i] = m[:name]
        }.sort { |a,b| a[0] <=> b[0] }.each { |num, name|
  				Object.const_get(name).new.migrate
  				execute "INSERT INTO mmigs (num, name) VALUES (#{num},'#{name}')"
        }
      end
    
      # Rolls back a single migration
      def rollback
        create_mig_table
        res = execute("WITH max AS (SELECT max(num) FROM mmigs) SELECT max.max as num,mmigs.name FROM max,mmigs WHERE mmigs.num=max.max;").first

        unless res.nil?
          load root.join("mystic","migrations","#{res["num"]}_#{res["name"]}.rb")
          Object.const_get(res["name"]).new.rollback
          execute "DELETE FROM mmigs WHERE num=#{res["num"]}"
        end
      end
	
  	  # Creates a blank migration in mystic/migrations
  		def create_migration name=""
        _name = name.strip.capitalize
        raise ArgumentError, "Migration name must not be empty." if _name.empty?

  			migs = root.join "mystic","migrations"
  			num = migs.entries.map { |e| MIG_REGEX.match(e.to_s)[:num].to_i rescue 0 }.max.to_i+1

  			File.open(migs.join("#{num}_#{_name}.rb").to_s, 'w') { |f| f.write(template _name) }
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