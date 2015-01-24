module ActiveRecordProfiler
  class ReportsController < ApplicationController
    include ReportsHelper

    def index
      @report_options = report_options(params)
      collector = ActiveRecordProfiler::Collector.new
      @totals = collector.aggregate(:prefix => @report_options[:date])
      @top_locations = collector.sorted_locations(@report_options[:sort], 
          @report_options[:max_rows])
      top_item = @totals[@top_locations.first]
      @max_bar_value = bar_value(@report_options[:sort], top_item)
    end

    private
      def report_options(page_params)
        options = page_params.reverse_merge(
            :date => Time.now.strftime(Collector::DATE_FORMAT),
            :sort => Collector::DURATION,
            :max_rows => 100
        )
        
        options[:sort] = options[:sort].to_i
        options[:max_rows] = options[:max_rows].to_i
        options[:link_location] = ActiveRecordProfiler.link_location

        return options
      end
  end
end
