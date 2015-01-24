module ActiveRecordProfiler
  class Engine < ::Rails::Engine
    isolate_namespace ActiveRecordProfiler

    rake_tasks do
      load 'active-record-profiler/tasks.rake'
    end

    initializer "active_record_profiler.apply_default" do
      # Copy module settings to collector class
      [:stats_flush_period, :profile_dir, :sql_ignore_pattern, 
          :app_path_pattern, :trim_root_path, :profile_self
      ].each do |config_item|
        ActiveRecordProfiler::Collector.send("#{config_item}=".to_sym, 
            ActiveRecordProfiler.send(config_item))
      end
    end
  end
end
