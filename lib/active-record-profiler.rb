require 'active-record-profiler/version'
require 'active-record-profiler/collector'
require 'active-record-profiler/log_subscriber'
require 'active-record-profiler/logger'
require 'active-record-profiler/profiler_view_helper'

require 'active-record-profiler/railtie' if defined?(Rails)

module ActiveRecordProfiler
  require 'fileutils'
  require 'json'
  begin
    require 'fastercsv'
  rescue Exception
    $stderr.puts("FasterCSV not available for use in ActiveRecordProfiler")
  end
end

