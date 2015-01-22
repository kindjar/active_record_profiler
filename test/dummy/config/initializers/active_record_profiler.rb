ActiveRecord::Base.logger =
    ActiveRecordProfiler::Logger.new(ActiveRecord::Base.logger)
ActiveRecordProfiler::LogSubscriber.attach_to :active_record
