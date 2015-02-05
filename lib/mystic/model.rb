#!/usr/bin/env ruby

# opts:
# :return - `:json`, `:rows`, `:nothing` defaults to :rows

module Mystic
  module Model
    RETURN_TYPES = [:rows, :json, :nothing].freeze
    DEFAULT_MODE = :default.freeze
    ACTIONS = [:select, :fetch, :create, :update, :delete].freeze   
    
    def self.extended b; included(b); end
    def self.included b
      b.extend SQLGeneration
      b.extend DSL
      b.include DefaultActions
    end
    
    module DefaultActions
      def self.extended b; self.included b; end
      def self.included b
        b.module_eval do
          select_action do |params={}, opts={}|
            Mystic.execute sql(:select, params, opts)
          end
      
          fetch_action do |params={}, opts={}|
            res = select params, opts.merge({:singular => true})
            res.is_a?(String) ? res : (res.empty? ? {} : res.first)
          end
      
          create_action do |params={}, opts={}|
            res = Mystic.execute sql(:insert, params, opts.merge({:singular => true}))
            res.is_a?(String) ? res : (res.empty? ? {} : res.first)
          end
      
          update_action do |where={}, set={}, opts={}|
            res = Mystic.execute sql(:update, where, set, opts)
            opts[:singular] ? (res.empty? ? {} : res.first) : res
          end
      
          delete_action do |params={}, opts={}|
    			  res = Mystic.execute sql(:delete, params, opts)
            opts[:singular] ? (res.empty? ? {} : res.first) : res
          end
        end
      end
    end
    
    module DSL
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
      # example: row_to_json(res){}
      def pseudocolumn name, sql
        properties[:pseudocolumns][name] = sql
        name
      end
      
      # mounts a PL/pgSQL function on the model
      def function funcname, newname
        define_method (funcname.nil? || funcname.empty?) ? newname : funcname do |*args|
          Mystic.execute "SELECT * FROM #{funcname}(#{args.sqlize*','})"
        end
      end
      
      def cte name, sql
        properties[:cte][name] = sql
        name
      end
      
      # select, creat, fetch, update, delete actions
      ACTIONS.each do |action|
        define_method("#{action}_action".to_sym) { |mode = DEFAULT_MODE, &b| map_action action, mode, &b } # DSL method to define the action
        define_method(action.to_sym) { |*args| action_for(action, (Symbol === args.first ? args.shift : DEFAULT_MODE)).call *args } # Method to call an action
      end

      # Attributes of a model
      def default_table
        to_s.downcase.strip
      end
      
      # takes params for pseudocolumns
      def column_string include_pseudocols=true, params={}
        cols = columns.map { |c| "#{table_name.to_s.dblquote}.#{c.to_s.dblquote}" }
        cols.push *pseudocolumns.map { |name, sql| params.each { |k,v| sql.gsub!(":#{k}",v.sqlize) }; "(#{sql}) AS #{name.to_s}" } if include_pseudocols
        cols.join(',')
        #(columns.map { |c| "#{table_name.to_s.dblquote}.#{c.to_s.dblquote}" }+pseudocolumns.map { |name, sql| params.each { |k,v| sql.gsub!(":#{k}",v.sqlize) }; "(#{sql}) AS #{name.to_s}" }).join(',')
      end
      
      def cte_string
        properties[:cte].map { |name, sql| "#{name} as (#{sql})" }.join(',')
      end
      
      def cte_expressions
        properties[:cte]
      end
      
      def columns
        properties[:columns].empty? ? [:*] : properties[:columns]
      end
      
      def pseudocolumns
        properties[:pseudocolumns]
      end
      
      def table_name
        properties[:table]
      end
      
      # Contains information from the DSL
      def properties
        unless defined? @__properties
          @__properties = {
            :table => default_table,
            :columns => [],
            :pseudocolumns => {},
            :actions => Hash[ACTIONS.map { |a| [a, {}] }],
            :cte => {}
          }
        end
        @__properties
      end
      
      private
      
      def map_action action, mode, &b
        (properties[:actions][action] ||= {})[mode] = b#ModelAction.new(&b)
      end
      
      def action_for action, mode
        (properties[:actions][action] ||= {})[mode]
      end
    end
    
    module SQLGeneration
      # SQL generation
      def decorate sql, opts={}
        raise ArgumentError, "No SQL to decorate." if sql.nil? || sql.empty?
      
        retrn = opts[:return] || opts["return"] || :rows
        singular = (opts[:singular] || opts["singular"] || false) == true
        singular = true if sql[0..5] == "INSERT"
      
        raise ArgumentError, "Return type (:return) must be either #{RETURN_TYPES.map(&:to_s).join(", ")}" unless RETURN_TYPES.include? retrn

        sql << " RETURNING #{column_string false}" if retrn != :nothing && sql[0..5] != "SELECT"
      
        case retrn
        when :rows, :nothing then sql
        when :json
          s = ["SELECT"]
          s << singular ? "row_to_json(\"res\")" : "array_to_json(array_agg(\"res\"))"
          s << "AS #{Mystic.config.json_column.dblquote}"
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
          
    			where = params.select { |k,_| columns.include? k }.sqlize

          sql = []
          sql << "WITH #{cte_string}" unless cte_expressions.empty?
          sql << "SELECT #{column_string(true, params.reject { |k,_| columns.include? k })}"
          sql << "FROM #{table_name}#{cte_expressions.empty? ? '' : ',' }"
          sql << cte_expressions.keys.map(&:to_s).join(',')
    			sql << "WHERE #{where*' AND '}" unless where.empty?
    			sql << "LIMIT #{count.to_i}" if count > 0
		
          decorate sql*' ', opts
        when :update
          raise ArgumentError, "Update queries must set something." if set.empty?
          decorate "UPDATE #{table_name.dblquote} SET #{set.symbolize.sqlize*','} WHERE #{where.sqlize*' AND '}", opts
        when :insert
          decorate "INSERT INTO #{table_name.to_s.dblquote} (#{params.keys.symbolize.sqlize*','}) VALUES (#{params.values.sqlize*','})", opts
        when :delete
          decorate "DELETE FROM #{table_name.to_s.dblquote} WHERE #{params.symbolize.sqlize*' AND '}", opts
        end
      end
    end
  end
end