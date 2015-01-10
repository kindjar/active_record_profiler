require 'active_record/log_subscriber'

module ActiveRecordProfiler
  class LogSubscriber < ActiveRecord::LogSubscriber
    def sql(event)
      start_time = Time.now.to_f
      payload = event.payload

      duration = event.duration
      sql_string = payload[:sql]

      begin
        collector = ActiveRecordProfiler::Collector.instance
        loc = collector.call_location_name
        collector.record_caller_info(loc, duration, sql_string.strip)

        collector.record_self_info((Time.now.to_f - start_time), 'updating profiler stats') if ActiveRecordProfiler::Collector.profile_self?

        start_time = Time.now.to_f
        if collector.should_flush_stats?
          collector.flush_query_sites_statistics 
          collector.record_self_info((Time.now.to_f - start_time), 'flushing profiler stats') if ActiveRecordProfiler::Collector.profile_self?
        end
      rescue Exception => e
        Rails.logger.error("Caught exception in #{self.class}: #{e} at #{e.backtrace.first}")
      end
    end

  end
end
