#!/usr/bin/env ruby

require "json"

#
# ENV keys
#
# 

module Mystic
  class Queue
    DEFAULT_QUEUE = :default.freeze
    TOP_BOUND = (ENV["MYSTIC_TOP_BOUND"] || 9).to_i.freeze
    
    def enqueue meth, queue, *args
      Mystic.execute "INSERT INTO \"mystic_jobs\" (q_name, method, args) VALUES (#{queue.to_s.quote},#{meth.to_s.quote},#{JSON.dump(args)})"
    end
    
    def enqueue_default meth, *args
      enqueue meth, DEFAULT_QUEUE, *args
    end
    
    def count queue=DEFAULT_QUEUE
      Mystic.execute("SELECT COUNT(id)::integer as count FROM \"mystic_jobs\" WHERE q_name=#{queue}")[0]["count"].to_i
    end
    
    def unlock_orphaned_jobs queue
      Mystic.execute "UPDATE \"mystic_jobs\" SET locked_at=NULL, locked_by=NULL WHERE q_name=#{queue.to_s.quote} AND locked_by NOT IN (SELECT pid FROM pg_stat_activity)"
    end
    
    def work queue=nil, wait=nil, concurrency=nil
      queue ||= DEFAULT_QUEUE
      wait ||= 5
      concurrency ||= 1
      
      workers = concurrency.times.map { Mystic::Worker.new :queue => queue, :wait => wait }
      
      trap "INT" do
        log $stderr, "Received INT. Shutting down."
        workers.each(&:stop)
      end

      trap "TERM" do
        log $stderr, "Received Term. Shutting down."
        workers.each(&:stop)
      end
      
      workers.each { |w| Thread.start(w) { |worker| worker.start } }
    end
    
    def lock_head queue
      r = Mystic.execute "SELECT * FROM lock_head(#{queue.to_s.quote}, #{TOP_BOUND.to_s.escape})"
      
      unless r.empty?
        r = r.first
        {}.tap do |job|
          job[:id] = r["id"]
          job[:q_name] = r["q_name"]
          job[:method] = r["method"]
          job[:args] = JSON.parse(r["args"])
          job[:scheduled_at] = Time.parse(r["scheduled_at"]) if r["scheduled_at"]
        end
      end
    end
    
    def unlock id
      Mystic.execute "UPDATE \"mystic_jobs\" SET locked_at=NULL WHERE id=#{id.to_s.escape}"
    end
    
    def delete queue, id
      Mystic.execute "DELETE FROM \"mystic_jobs\" WHERE q_name=#{queue.to_s.quote} AND id=#{id.to_s.escape}"
    end
    
    def empty queue
      Mystic.execute "DELETE FROM \"mystic_jobs\" WHERE q_name=#{queue.to_s.quote}"
    end
    
    def wait time, *channels
      listen *channels
      Mystic.wait_for_notify time
      unlisten *channels
    end
    
    def listen *cnls
      Mystic.execute cnls.map { |c| "LISTEN \"#{c.to_s}\"" }.join(";")
    end
    
    def unlisten *cnls
      Mystic.execute cnls.map { |c| "UNLISTEN \"#{c.to_s}\"" }.join(";")
    end
    
    def log output=$stdout, str
      output.puts str
    end
    
    def setup
  		Mystic.execute <<-SQL
      CREATE TABLE mystic_jobs (
        id bigserial PRIMARY KEY,
        q_name text not null check (length(q_name) > 0),
        method text not null check (length(method) > 0),
        args   text not null, -- look into changing this to JSON
        locked_at timestamptz,
        locked_by integer,
        created_at timestamptz default now(),
        scheduled_at timestamptz default now()
      );

      CREATE INDEX idx_mystic_on_name_only_unlocked ON mystic_jobs (q_name, id) WHERE locked_at IS NULL;
      CREATE INDEX idx_mystic_on_scheduled_at_only_unlocked ON mystic_jobs (scheduled_at, id) WHERE locked_at IS NULL;
      
			CREATE OR REPLACE FUNCTION lock_head(q_name text, top_boundary integer)
			RETURNS SETOF mystic_jobs AS $$
			DECLARE
				unlocked bigint;
				relative_top integer;
				job_count integer;
			BEGIN
		 		EXECUTE 'SELECT count(*) FROM (SELECT * FROM mystic_jobs WHERE locked_at IS NULL AND q_name=' || quote_literal(q_name) || ' LIMIT ' || quote_literal(top_boundary) || ') limited'
				INTO job_count;

				SELECT TRUNC(random() * (top_boundary - 1))
				INTO relative_top;

				IF job_count < top_boundary THEN
					relative_top = 0;
				END IF;

				LOOP
          BEGIN
            EXECUTE 'SELECT id FROM mystic_jobs WHERE locked_at IS NULL AND q_name=' || quote_literal(q_name) || ' ORDER BY id ASC LIMIT 1 OFFSET ' || quote_literal(relative_top) || ' FOR UPDATE NOWAIT'
		   			INTO unlocked;
		  			EXIT;
		 			EXCEPTION
		    		WHEN lock_not_available THEN
		      		-- do nothing. loop again and hope we get a lock
						END;
				END LOOP;

				RETURN QUERY EXECUTE 'UPDATE mystic_jobs SET locked_at=(CURRENT_TIMESTAMP), locked_by=(select pg_backend_pid()) WHERE id=$1 AND locked_at IS NULL RETURNING *'
				USING unlocked;

				RETURN;
			END;
			$$ LANGUAGE plpgsql;
			
			CREATE FUNCTION notify_job() RETURNS trigger as $$
			BEGIN
		  	perform pg_notify(new.q_name, '');
		  	return NULL;
			END;
			$$ language plpgsql;
      SQL
    end
    
    def teardown
  		Mystic.execute "DROP FUNCTION lock_head(q_name text, top_boundary integer)"
  		Mystic.execute "DROP FUNCTION notify_job() cascade"
      Mystic.execute "DROP TABLE mystic_jobs cascade"
    end
  end
  
  singleton_class.class_eval do
    def queue
      @queue ||= Mystic::Queue.new
    end
    
    def queue= q
      raise ArgumentError, "Queue cannot be nil." if q.nil?
      @queue = q
    end
  end
end

module Mystic
  class Worker
    def initialize opts={}
      @wait_interval = opts[:wait].to_i
      @queue = opts[:queue].to_s
      @running = false
    end
    
    def start
      Mystic.queue.unlock_orphaned_jobs @queue
      @running = true
      work
    end
    
    def stop
      @running = false
      Mystic.queue.unlisten @queue
    end
    
    def work
      while @running
        job = Mystic.queue.lock_head @queue 
        if job
          start = Time.now
          finished = false
          begin
            receiver_str, _, message = job[:method].rpartition '.'
            Object.const_get(receiver_str).send(message, *job[:args])
            Mystic.queue.delete job[:id]
            finished = true
          rescue => e
            handle_failure(job, e)
            finished = true
          ensure
            Mystic.queue.unlock(job[:id]) unless finished
            Mystic.queue.log "time-to-process=#{(Time.now - start) * 1000} source=#{@queue}"
          end
        else
          Mystic.queue.wait @wait_interval, @queue
        end
      end
    end
  end
end