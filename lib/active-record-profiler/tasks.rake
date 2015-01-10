namespace "profiler" do

  desc 'Aggregate profile data and display locations with the longest total durations'
  task :aggregate => :environment do
    top_n = ENV['max_lines'].present? ? ENV['max_lines'].to_i : 50
    show_longest_sql = ENV['show_sql'] == 'true' ? true : false
    prefix = ENV['prefix'].present? ? ENV['prefix'] : nil
    compact = case ENV['compact']
      when 'date'
        :date
      when 'hour'
        :hour
      else
        nil
    end

    if compact && prefix.nil?
      case compact
      when :date
        prefix = 1.day.ago.strftime(ActiveRecordProfiler::Collector::DATE_FORMAT)
      when :hour
        prefix = 1.hour.ago.strftime(ActiveRecordProfiler::Collector::DATE_FORMAT + ActiveRecordProfiler::HOUR_FORMAT)
      end
    end
    
    collector = ActiveRecordProfiler::Collector.new
    totals = collector.aggregate(:prefix => prefix, :compact => compact)
    top_locs = collector.sorted_locations(ActiveRecordProfiler::Collector::DURATION, top_n)
    
    top_locs.each do |loc|
      data = show_longest_sql ? totals[loc] : totals[loc][0..-2]
      puts "#{loc}: #{data.join(', ')}"
    end
  end
  
  desc 'Clear out the profiler data diretory'
  task :clear_data => :environment do
    ActiveRecordProfiler::Collector.clear_data
  end
  
end
