require 'active-record-profiler'
require 'rails'

module ActiveRecordProfiler
  class Railtie < Rails::Railtie
    initializer "active_record_profiler.add_to_abstract_adapter" do |app|
      ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, ActiveRecordProfiler
      ActionView::Base.send :include, ProfilerViewHelper
      Collector.trim_root_path = Rails.root.expand_path + "/"
      Collector.profile_dir = Rails.root.join("log", "profiler_data")
    end

    rake_tasks do
      load 'active-record-profiler/tasks.rake'
    end
  end
end
