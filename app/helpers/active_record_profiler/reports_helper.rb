module ActiveRecordProfiler
  module ReportsHelper
    def report_column_header_link(column_id, sort_by, label, page_params)
      link_to_unless(sort_by == column_id, 
        label, 
        page_params.merge(:sort => column_id)
      )
    end

    def bar_value(sort, item)
      return 0 unless item && sort
      if sort == ActiveRecordProfiler::Collector::AVG_DURATION
        item[Collector::DURATION] / item[Collector::COUNT]
      else
        item[sort]
      end
    end

    def breakable_path(path)
      h(path).gsub('/', "&#8203;/")
    end

    def location_description(path, line_number)
      "#{breakable_path(path)}: #{h(line_number)}".html_safe
    end
  end
end
