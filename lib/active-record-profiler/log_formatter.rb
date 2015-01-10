require 'active_support/tagged_logging'

module ActiveRecordProfiler
  class LogFormatter < ::Logger::Formatter
    include ActiveSupport::TaggedLogging::Formatter

    # This method is invoked when a log event occurs
    def call(severity, timestamp, progname, msg)
      message = msg

      if String === msg 
        start_time = Time.now.to_f
        match = /^\s*(?:\e\[\d+m)*(:?[^(]*)\(([0-9.]+)\s*([a-z]s(:?econds)?)\)(?:\e\[\d+m)*\s*(.*)/.match(msg)

        if match
          seconds = match[1].to_f
          units = match[2]
          sql = match[3]
          loc = collector.call_location_name

          message = "#{msg} CALLED BY '#{formatted_location(loc)}'"
        end
      end

      super(severity, timestamp, progname, message)
    end

    def collector
      ActiveRecordProfiler::Collector.instance
    end

    def formatted_location(loc)
      return loc unless Rails.configuration.colorize_logging
      "\e[4;32;1m#{loc}\e[0m"
    end
  end
end
