require 'logger'

module ActiveRecordProfiler
  class Logger < SimpleDelegator

    def add(severity, message = nil, progname = nil, &block)
      return true if (severity || ::Logger::Severity::UNKNOWN) < self.level

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
          progname = self.progname
        end
      end

      message = add_call_site_to_message(message)

      super(severity, message, progname, &block)
    end

    # Define all of the basic logging methods so that they invoke our add()
    # method rather than delegating to the delagatee's methods, which will then
    # invoke the delegatee's add() method that does not add call-site 
    # information.
    [:debug, :info, :warn, :error, :fatal, :unknown].each do |level|
      define_method(level) do |progname = nil, &block|
        add(
            ::Logger::Severity.const_get(level.to_s.upcase),
            nil,
            progname,
            &block
        )
      end
    end

    protected
      def add_call_site_to_message(msg)
        message = msg

        if String === msg 
          match = /^\s*(?:\e\[\d+m)*(:?[^(]*)\(([0-9.]+)\s*([a-z]s(:?econds)?)\)(?:\e\[\d+m)*\s*(.*)/.match(msg)

          if match
            loc = collector.call_location_name
            message = "#{msg} CALLED BY '#{formatted_location(loc)}'"
          end
        end

        return message
      end
  
      def collector
        ActiveRecordProfiler::Collector.instance
      end

      def formatted_location(loc)
        if Rails.configuration.colorize_logging
          "\e[4;32;1m#{loc}\e[0m"
        else
          loc
        end
      end

  end
end
