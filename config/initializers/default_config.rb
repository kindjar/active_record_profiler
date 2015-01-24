ActiveRecordProfiler.stats_flush_period = 1.hour
ActiveRecordProfiler.profile_dir = Rails.root.join("log", "profiler_data")
ActiveRecordProfiler.sql_ignore_pattern = 
  /^(SHOW (:?FULL )?FIELDS |SET SQL_AUTO_IS_NULL|SET NAMES |EXPLAIN |BEGIN|COMMIT|PRAGMA )/i
ActiveRecordProfiler.app_path_pattern = Regexp.new(Regexp.quote("#{Rails.root.expand_path}/") + "(:?app|lib|vendor)/")
ActiveRecordProfiler.trim_root_path = "#{Rails.root.expand_path}/"
ActiveRecordProfiler.profile_self = false
ActiveRecordProfiler.link_location = false
