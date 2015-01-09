require 'active-record-profiler/version'
require 'active-record-profiler/collector'
require 'active-record-profiler/profiler_view_helper'

require 'active-record-profiler/railtie' if defined?(Rails)

module ActiveRecordProfiler
  require 'fileutils'
  require 'json'
  begin
    require 'fastercsv'
  rescue Exception => e
    $stderr.puts("FasterCSV not available for use in ActiveRecordProfiler")
  end
  
  def self.included(base)    
    base.class_eval do
      
      def log_info_with_caller_tracking(sql, name, seconds)
        if ActiveRecordProfiler::Collector.profiler_enabled_for_current_env?
          start_time = Time.now.to_f
          retval = nil
          begin
            collector = ActiveRecordProfiler::Collector.instance
            loc = collector.call_location_name
            collector.record_caller_info(loc, seconds, sql.strip)
            
            loc = "\e[4;32;1m#{loc}\e[0m" if ActiveRecord::Base.colorize_logging
            collector.record_self_info((Time.now.to_f - start_time), 'updating profiler stats') if ActiveRecordProfiler::Collector.profile_self?
            retval = log_info_without_caller_tracking(sql + " CALLED BY '#{loc}'", name, seconds)

            start_time = Time.now.to_f
            if collector.should_flush_stats?
              collector.flush_query_sites_statistics 
              collector.record_self_info((Time.now.to_f - start_time), 'flushing profiler stats') if ActiveRecordProfiler::Collector.profile_self?
            end
          rescue Exception => e
            Rails.logger.error("Caught exception in ActiveRecordProfiler: #{e} at #{e.backtrace.first}")
            retval = log_info_without_caller_tracking(sql, name, seconds)
          end
          
          return retval
        else
          log_info_without_caller_tracking(sql, name, seconds)
        end
      end
      # alias_method_chain :log_info, :caller_tracking
      
    end
  end
end

