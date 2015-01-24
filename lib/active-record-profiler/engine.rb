module ActiveRecordProfiler
  class Engine < ::Rails::Engine
    isolate_namespace ActiveRecordProfiler

    initializer "active_record_profiler.defaults" do |app|
      Collector.trim_root_path = "#{Rails.root.expand_path}/"
      Collector.profile_dir = Rails.root.join("log", "profiler_data")
      ActiveRecordProfiler.link_location = false
    end

    rake_tasks do
      load 'active-record-profiler/tasks.rake'
    end
  end
end
