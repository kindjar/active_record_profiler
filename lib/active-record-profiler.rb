require 'active-record-profiler/version'
require 'active-record-profiler/collector'
require 'active-record-profiler/log_subscriber'
require 'active-record-profiler/logger'
require "active-record-profiler/engine" if defined?(Rails)

module ActiveRecordProfiler
  require 'fileutils'
  require 'json'
  
  mattr_accessor :link_location, :stats_flush_period, :profile_dir, 
      :sql_ignore_pattern, :app_path_pattern, :trim_root_path, :profile_self
end

