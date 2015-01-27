require 'active_record/log_subscriber'

module ActiveRecordProfiler
  class LogSubscriber < ActiveRecord::LogSubscriber
    CACHE_PAYLOAD_NAME = 'CACHE'

    def sql(event)
      start_time = Time.now.to_f
      payload = event.payload
      return if payload[:name] == CACHE_PAYLOAD_NAME

      duration = event.duration / 1000.0  # convert from ms to seconds
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
