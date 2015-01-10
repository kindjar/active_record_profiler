require 'active-record-profiler'
require 'rails'

module ActiveRecordProfiler
  class Railtie < Rails::Railtie
    initializer "active_record_profiler.add_to_abstract_adapter" do |app|
      # ActiveRecordProfiler::LogSubscriber.attach_to :active_record
      ActionView::Base.send :include, ProfilerViewHelper

      Collector.trim_root_path = "#{Rails.root.expand_path}/"
      Collector.profile_dir = Rails.root.join("log", "profiler_data")

      ActiveRecord::Base.logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger.formatter = ActiveRecordProfiler::LogFormatter.new
    end

    rake_tasks do
      load 'active-record-profiler/tasks.rake'
    end
  end
end
