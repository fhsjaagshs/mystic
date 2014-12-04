#!/usr/bin/env ruby

# opts:
# :return - `:json`, `:rows`, `:nothing` defaults to :rows

module Mystic
  module Model
    RETURN_TYPES = [:rows, :json, :nothing].freeze
    
    DEFAULT_MODE = :default.freeze
    ACTIONS = [:select, :fetch :create, :update, :delete].freeze   
    DEFAULT_ACTIONS = {
      :select => lambda { |params={}, opts={}|
        Mystic.execute sql(:select, params, opts)
      },
      :fetch => lambda { |params={}, opts={}| 
        properties[:actions][:select][:default].call params,opts.merge({:singular => true})
        res.is_a? String ? res : (res.count > 0 ? res.first : {})
      },
      :create => lambda { |params={}, opts={}|
        res = Mystic.execute sql(:insert, params, opts.merge({:singular => true}))
        res.is_a? String ? res : (res.count > 0 ? res.first : {})
      },
      :update => lambda { |where={}, set={}, opts={}|
        res = Mystic.execute sql(:update, where, set, opts)
        opts[:singular] ? (res.count > 0 ? res.first : {}) : res
      },
      :delete => lambda { |params={}, opts={}|
			  res = Mystic.execute sql(:delete, params, opts)
        opts[:singular] ? (res.count > 0 ? res.first : {}) : res
      }
    }.freeze
    
    def self.included base
      base.extend ClassMethods
    end
    
    module ClassMethods
      # Attributes of a model
      def default_table
        to_s.downcase.strip
      end
      
      def column_string
        columns+(pseudocolumns.map { |name, sql| "(#{sql}) AS #{name.to_s}" }).join ','
      end
      
      def columns
        (properties[:columns].empty? ? [:*] : properties[:columns]
      end
      
      def pseudocolumns
        properties[:pseudocolumns]
      end
      
      def table_name
        properties[:table]
      end
 
      # Contains information from the DSL
      def properties
        if @__properties.nil?
          @__properties = {}
          @__properties[:table] = default_table
          @__properties[:columns] = []
          @__properties[:pseudocolumns] = {}
          @__properties[:actions] = {}
          Mystic::Model::ACTIONS.each { |action| @__properties[:actions][action] = {} }
          Mystic::Model::ACTIONS.each { |action| @__properties[:actions][action][DEFAULT_MODE] = DEFAULT_ACTIONS[action] }
        end
        @__properties
      end
    
      #
      # DSL
      #
      
      def table tblname
        properties[:table] = tblname.to_sym
        tblname
      end
    
      def column colname
        raise ArgumentError, "Must provide a name for this column" if colname.nil? || colname.empty?
        properties[:columns] ||= []
        properties[:columns] << colname.to_sym
        colname
      end
    
      # SQL for a value to be selected as a column
      # example:
      # row_to_json(res)
      def pseudocolumn name, sql
        properties[:pseudocolumns][name] = sql
        name
      end
      
      # mounts a PL/pgSQL function on the model
      def function funcname, newname
        define_method (funcname.nil? || funcname.empty?) ? newname : name do |*args|
          Mystic.execute "SELECT * FROM #{funcname}(#{args.sqlize*','})"
        end
      end
      
      #
      # CRUD actions
      #

      Mystic::Model::ACTIONS.each do |action|
        # DSL method to define the action
        define_method "#{action.to_s}_action".to_sym do |mode = DEFAULT_MODE, &b|
          valid = (b.parameters.count >= DEFAULT_ACTIONS[action].parameters.count) || (b.parameters.detect { |kind,_| kind == :rest })
          raise ArgumentError, "Invalid block for action '#{action}' on table '#{table_name}'." unless valid
          properties[:actions][action][mode] = b
        end
        
        # Method to call an action
        define_method action do |mode = DEFAULT_MODE, *args|
          properties[:actions][action][mode].call *args
        end
      end
      
      # SQL generation
      def decorate sql, opts={}
        raise ArgumentError, "No SQL to decorate." if sql.nil? || sql.empty?
      
        retrn = opts[:return] || opts["return"] || :rows
        singular = (opts[:singular] || opts["singular"] || false) == true
        singular = true if sql[0..5] == "INSERT"
      
        raise ArgumentError, "Return type (:return) must be either #{RETURN_TYPES.map(&:to_s).join(", ")}" unless RETURN_TYPES.include? retrn

        sql << " RETURNING #{colstr}" if retrn != :nothing && sql[0..5] != "SELECT"
      
        case retrn
        when :rows, :nothing then sql
        when :json
          s = ["SELECT"]
          s << singular ? "row_to_json(\"res\")" : "array_to_json(array_agg(\"res\"))"
          s << "AS #{Mystic::Postgres::REPR_COL.dblquote}"
          s << "FROM (#{sql}) \"res\""
          s << "LIMIT 1" if singular
          s*' '
        end
      end
    
      def sql op, params={}, set={}, opts={}
        case op
        when :select
          count = opts[:count] || opts["count"] || 0
          count = 1 if (opts[:singlular] || opts["singular"]) == true
    			where = params.sqlize

    			sql = ["SELECT #{column_string} FROM #{table_name}"]
    			sql << "WHERE #{where*' AND '}" unless where.empty?
    			sql << "LIMIT #{count.to_i}" if count > 0
		
          decorate sql*' ', opts
        when :update
          raise ArgumentError, "Update queries must set something." if set.empty?
          decorate "UPDATE #{table_name.dblquote} SET #{set.sqlize*','} WHERE #{where.sqlize*' AND '}", opts
        when :insert
          decorate "INSERT INTO #{table_name.dblquote} (#{entry.keys*','}) VALUES (#{entry.values.sqlize*','})", opts
        when :delete
          decorate "DELETE FROM #{table_name.dblquote} WHERE #{params.sqlize*' AND '}", opts
        end
      end
    end
  end
end