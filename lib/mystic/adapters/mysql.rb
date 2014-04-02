#!/usr/bin/env ruby

class MysqlAdapter < Adapter
  def connect(opts)
    create_pool do
      PG.connect(opts)
    end
  end
  
  def disconnect
    @pool.with do |instance|
      instance.close
    end
  end
  
  def exec(sql)
    return nil if @pool.nil?
    puts sql
    res = nil
    @pool.with do |instance|
      res = instance.exec(sql)
    end
    return res
  end
  
  def sanitize(string)
    res = nil
    @pool.with do |instance|
      res = instance.escape_string(string)
    end
    return res
  end
  
  def foreign_key_sql(tbl, column, delete_action, update_action)
    # http://www.postgresql.org/docs/9.3/static/tutorial-fk.html
  end
  
  def constraint_sql(name, conditions)
    "CONSTRAINT #{name} CHECK(#{conditions})"
  end
end