ActiveRecordProfiler::Collector.trim_root_path = "#{Rails.root.expand_path}/"
ActiveRecordProfiler::Collector.profile_dir = Rails.root.join("log", "profiler_data")
ActiveRecordProfiler.link_location = false
