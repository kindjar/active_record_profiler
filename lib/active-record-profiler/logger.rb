require 'logger'

module ActiveRecordProfiler
  class Logger < SimpleDelegator

    def add(severity, message = nil, progname = nil, &block)
      return true if (severity || ::Logger::Severity::UNKNOWN) < self.level
      start_time = Time.now.to_f

      called_block = false
      if message.nil?
        if block_given?
          message = yield
          called_block = true
        else
          message = progname
          progname = self.progname
        end
      end

      message = add_call_site_to_message(message)
      collector.record_self_info((Time.now.to_f - start_time), 'enhancing log line') if ActiveRecordProfiler::Collector.profile_self?

      # We don't use super() here to pass control to the delegate because if we 
      # do, there's no way to prevent super() from seeing the block and yielding
      # to it, and if we've already yielded to the block, this could result in a
      # double yield (if the message is nil after calling the block).
      if called_block
        # don't pass the block, since we already called it
        __getobj__.add(severity, message, progname)
      else  
        __getobj__.add(severity, message, progname, &block)
      end
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
