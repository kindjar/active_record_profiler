# Include hook code here

ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, ActiveRecordProfiler
