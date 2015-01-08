#!/usr/bin/env ruby

require_relative "./database"

module Mystic
  module CommandLine
    MPATH = Mystic.root.join("mystic","migrations").freeze
    MREGEX = /^(?<num>\d+)_(?<name>[a-zA-Z]+)\.rb$/.freeze # example: 1_MigrationClassName.rb

    MIGTABLE = "mmgis".dblquote.freeze
    
    CREATE_TABLE_SQL = "CREATE TABLE IF NOT EXISTS #{MIGTABLE} (num integer, name text)".freeze
    LAST_MIG_NUM_SQL = "SELECT max(num) as num FROM #{MIGTABLE.dblquote}".freeze
    LAST_MIG_SQL = "WITH max AS (#{LAST_MIG_NUM_SQL}) SELECT max.num as num,#{MIGTABLE}.name as name FROM max,#{MIGTABLE} WHERE #{MIGTABLE}.num=max.num;".freeze
    
    class << self
      def setup
        execute CREATE_TABLE_SQL
      end
      
      def work queue, wait, concurrency
        Mystic.queue.work queue, wait, concurrency
      end

      # Runs every yet-to-be-ran migration
      def migrate
        setup
        last_mig_num = execute(LAST_MIG_NUM_SQL).first["num"] rescue 0

        migs = MPATH.entries
               .map { |fn| MREGEX.match fn }
               .compact
               .map { |m| [m[:num].to_t, m[:name].to_s] }
               .reject { |k,_| k < last_mig_num }
               .sort_by { |k,_| k }
               .each { |num, name|
                 Object.const_get(name).new.migrate
                 execute "INSERT INTO #{MIGTABLE} (num,name) VALUES (#{num.to_s.escape},'#{name.sqlize}')"
               }
      end
    
      # Rolls back a single migration
      def rollback
        setup
        res = execute(LAST_MIG_SQL).first

        unless res.nil?
          load root.join("mystic","migrations","#{res["num"]}_#{res["name"]}.rb")
          Object.const_get(res["name"]).new.rollback
          execute "DELETE FROM #{MIGTABLE} WHERE num=#{res["num"].sqlize}"
        end
      end
	
      # Creates a blank migration in mystic/migrations
      def create_migration name=""
        num = MPATH.entries.map { |e| MREGEX.match(e.to_s)[:num].to_i rescue 0 }.max.to_i+1
        MPATH.join("#{num}_#{_name}.rb").write template(name.strip.capitalize.gsub(/\S+/,''))
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
