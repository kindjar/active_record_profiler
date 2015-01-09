module ActiveRecordProfiler
  module ProfilerViewHelper
    def profiler_date_filter_form(page_params, options = {})
      date    = options[:date] || page_params[:date] || Time.now.strftime(ActiveRecordProfiler::DATE_FORMAT)
      sort_by = options[:sort] || page_params[:sort] || ActiveRecordProfiler::DURATION
      
      content_tag(:form,
        [
          hidden_field_tag(:sort, sort_by),
          label_tag(:profiler_date, 'Filter by date-hour prefix (yyyy-mm-dd-hh):'),
          text_field_tag(:date, date, {:size =>10, :id => :profiler_date}),
          submit_tag('Go')
        ]
      )
    end
    
    def profiler_report(page_params, options = {})
      date      = options[:date]      || page_params[:date]     || Time.now.strftime(ActiveRecordProfiler::DATE_FORMAT)
      sort_by   = (options[:sort]     || page_params[:sort]     || ActiveRecordProfiler::DURATION).to_i
      max_rows  = (options[:max_rows] || page_params[:max_rows] || 100).to_i
      collector = options[:collector] || ActiveRecordProfiler::Collector.new
      
      options = options.reverse_merge(:table => 'profiler', :link_locations => false)
      
      totals = collector.aggregate(:prefix => date)
      top_locs = collector.sorted_locations(sort_by.to_i, max_rows)
      
      rows = []

      if top_locs.present?
        top_item = totals[top_locs.first]
        max_bar = sort_by == ActiveRecordProfiler::AVG_DURATION ? (top_item[0]/top_item[1]) : top_item[sort_by]
    
        top_locs.each do |location|
          rows << content_tag(
            :tr, 
            profiler_report_cols(location, totals[location], sort_by, max_bar, options),
            {:class => "#{cycle('oddRow', 'evenRow')} #{options[:row]}"}
          )
        end
      end
      
      content_tag(
        :table, [
          content_tag(:thead,
            profiler_report_header(page_params, sort_by, max_rows, options)
          ),
          content_tag(:tbody,
            rows
          )
        ],
        {:class => options[:table]}
      )   
    end
    
    def profiler_column_header_link(column_id, sort_by, page_params)
      labels = {
        ActiveRecordProfiler::DURATION => '<b>Total Duration (s)</b>',
        ActiveRecordProfiler::COUNT => '<b>Count</b>',
        ActiveRecordProfiler::AVG_DURATION => '<b>Avg. Duration (ms)</b>',
        ActiveRecordProfiler::LONGEST => '<b>Max. Duration (ms)</b>',
      }
      
      link_to_unless(sort_by == column_id, 
        labels[column_id], 
        page_params.merge(:sort => column_id)
      )
    end

    def profiler_report_header(page_params, sort_by, max_rows, options)
      column_styles = options[:column_styles] || {
        :location => 'width:19%',
        :total_duration => 'width:6%',
        :count => 'width:6%',
        :average_duration => 'width:6%',
        :max_duration => 'width:6%',
        :longest_sql => 'width:57%'
      }

      headers = []

      headers << content_tag(:th, 'Location', {:style => column_styles[:location]})

      headers << content_tag(
        :th, 
        profiler_column_header_link(ActiveRecordProfiler::DURATION, sort_by, page_params),
        {:style => column_styles[:total_duration]}
      )

      headers << content_tag(
        :th, 
        profiler_column_header_link(ActiveRecordProfiler::COUNT, sort_by, page_params),
        {:style => column_styles[:count]}
      )

      headers << content_tag(
        :th, 
        profiler_column_header_link(ActiveRecordProfiler::AVG_DURATION, sort_by, page_params),
        {:style => column_styles[:average_duration]}
      )

      headers << content_tag(
        :th, 
        profiler_column_header_link(ActiveRecordProfiler::LONGEST, sort_by, page_params),
        {:style => column_styles[:max_duration]}
      )

      headers << content_tag(:th, 'SQL for Max Duration', {:style => column_styles[:longest_sql]})
      
      content_tag(:tr, headers, {:class => options[:header]})
    end
    
    def profiler_report_cols(location, row_data, sort_by, max_bar, options)
      columns = []

      loc_parts = location.split(':')
      breakble_loc = loc_parts[0].gsub('/', "&#8203;/")
      this_bar = sort_by == ActiveRecordProfiler::AVG_DURATION ? (row_data[0]/row_data[1]) : row_data[sort_by]

      columns << content_tag(
        :td, [
          link_to_if(
            options[:link_locations],
            "#{breakble_loc}: #{loc_parts[1]}", 
            "javascript:showSourceFile('#{loc_parts[0]}', '#{loc_parts[1]}');"
          ),
          content_tag(:div, '', {:style=>"background-color:red; height:1.2em; width:#{100*this_bar/max_bar}%"})
        ], {:title=>loc_parts[2]}
      )

      columns << content_tag(:td, number_with_precision(row_data[0], :precision => 3), {:class => "numeric"})
      columns << content_tag(:td, number_with_delimiter(row_data[1]), {:class => "numeric"})
      columns << content_tag(:td, number_with_precision(row_data[0]/row_data[1] * 1000, :precision => 3), {:class => "numeric"})
      columns << content_tag(:td, number_with_precision(row_data[2] * 1000, :precision => 3), {:class => "numeric"})
      columns << content_tag(:td, h(row_data[3]), {:class => "sql"})

      columns.join('')
    end
    
    def profiler_report_local_path_form
      content_tag(:form, 
        [
          label_tag(:source_root, 'Local gistweb source path (for location links):'),
          text_field_tag(:source_root, nil, {:size => 50, :id => :source_root})
        ]
      )
    end
    
    def profiler_local_path_link_formatters
      @@profiler_local_path_link_formatters ||= {
        :textmate => '"txmt://open/?url=file://" + root + "/" + file + "&line=" + line',
      }
    end
    
    def profile_report_local_path_javascript(link_format = :textmate)
      formatter = profiler_local_path_link_formatters[link_format]
      
      javascript_tag(%Q[
        var profiler_source_root = $('#source_root');
        
        function setDBProfSourceRoot(value) {
          var exdate = new Date(); 
          var expireDays = 356;
          exdate.setDate(exdate.getDate() + expireDays);
          document.cookie = "db_prof_source_root=" + escape(value) + ";expires=" + exdate.toGMTString();
        }
      
        function getDBProfSourceRoot() {
          if (document.cookie.length>0) {
            var c_name = "db_prof_source_root";
            c_start = document.cookie.indexOf(c_name + "=");
            if (c_start != -1) {
              c_start = c_start + c_name.length + 1;
              c_end = document.cookie.indexOf(";", c_start);
              if (c_end == -1) { c_end = document.cookie.length; }
              var root = document.cookie.substring(c_start, c_end);
              if (root != "") {
                return unescape(root);
              }
            }
          }
          return "#{Rails.root}";
        }
        function showSourceFile(file, line){
          var root = profiler_source_root.val();
          if (root == "") { root = "#{Rails.root}"}
          window.location = #{formatter};
        }
        
        profiler_source_root.val(getDBProfSourceRoot());
        profiler_source_root.change(function(e){
          setDBProfSourceRoot($(this).val());
        });
      ])
    end
  end
end
