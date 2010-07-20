# Include hook code here
require 'profiler_view_helper'

ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, ActiveRecordProfiler

ActionView::Base.send :include, ProfilerViewHelper