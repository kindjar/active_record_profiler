module ActiveRecordProfiler
  class LogSubscriber < ActiveRecord::LogSubscriber
    def sql(event)
      return unless ActiveRecordProfiler::Collector.profiler_enabled_for_current_env?

      start_time = Time.now.to_f
      payload = event.payload
      Rails.logger.debug("Payload: #{payload.inspect}")

      begin
        collector = ActiveRecordProfiler::Collector.instance
        loc = collector.call_location_name
        collector.record_caller_info(loc, seconds, sql.strip)

        loc = "\e[4;32;1m#{loc}\e[0m" if ActiveRecord::Base.colorize_logging
        collector.record_self_info((Time.now.to_f - start_time), 'updating profiler stats') if ActiveRecordProfiler::Collector.profile_self?

        start_time = Time.now.to_f
        if collector.should_flush_stats?
          collector.flush_query_sites_statistics 
          collector.record_self_info((Time.now.to_f - start_time), 'flushing profiler stats') if ActiveRecordProfiler::Collector.profile_self?
        end
      rescue Exception => e
        Rails.logger.error("Caught exception in #{self.class}: #{e} at #{e.backtrace.first}")
      end

      name  = "#{payload[:name]} (#{event.duration.round(1)}ms)"
      sql   = payload[:sql]
      binds = nil

      unless (payload[:binds] || []).empty?
        binds = "  " + payload[:binds].map { |col,v|
          render_bind(col, v)
        }.inspect
      end

      if odd?
        name = color(name, CYAN, true)
        sql  = color(sql, nil, true)
      else
        name = color(name, MAGENTA, true)
      end

      debug "  #{name}  #{sql}#{binds}"
    end

  end
end

ActiveRecordProfiler::LogSubscriber.attach_to :active_record
