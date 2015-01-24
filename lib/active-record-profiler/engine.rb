module ActiveRecordProfiler
  class Engine < ::Rails::Engine
    isolate_namespace ActiveRecordProfiler

    rake_tasks do
      load 'active-record-profiler/tasks.rake'
    end
  end
end
