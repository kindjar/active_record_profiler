require 'active-record-profiler/version'
require 'active-record-profiler/collector'
require 'active-record-profiler/log_subscriber'
require 'active-record-profiler/logger'
require "active-record-profiler/engine" if defined?(Rails)

module ActiveRecordProfiler
  require 'fileutils'
  require 'json'
  
  mattr_accessor :link_location
end

