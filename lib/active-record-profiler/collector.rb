module ActiveRecordProfiler
  class Collector
    DURATION = 0
    COUNT = 1
    LONGEST = 2
    LONGEST_SQL = 3
    LOCATION = -1
    AVG_DURATION = -2
    
    DATE_FORMAT = '%Y-%m-%d'
    HOUR_FORMAT = '-%H'
    DATETIME_FORMAT = DATE_FORMAT + HOUR_FORMAT + '-%M'
    AGGREGATE_QUIET_PERIOD = 1.minutes
    
    CSV_DURATION = 0
    CSV_COUNT = 1
    CSV_AVG = 2
    CSV_LONGEST = 3
    CSV_LOCATION = 4
    CSV_LONGEST_SQL = 5

    NON_APP_CODE_DESCRIPTION = 'Non-application code'
         
    cattr_accessor :profiler_enabled
    self.profiler_enabled = true
    
    # You can control the (approximate) frequency of statistics flushes by setting
    # ActiveRecordProfiler::Collector.stats_flush_period = 1.hour
    cattr_accessor :stats_flush_period
    self.stats_flush_period = 1.hour
    
    # Directory where profile data is recorded
    cattr_accessor :profile_dir

    # Any SQL statements matching this pattern will not be tracked by the profiler output
    # (though it will still appear in the enhanced SQL logging).
    cattr_accessor :sql_ignore_pattern
    self.sql_ignore_pattern = /^(SHOW FIELDS |SET SQL_AUTO_IS_NULL|SET NAMES |EXPLAIN |BEGIN|COMMIT|PRAGMA )/i
    
    cattr_accessor :app_path_pattern
    self.app_path_pattern = Regexp.new(Regexp.quote("/app/"))
    
    cattr_accessor :trim_root_path
    
    cattr_accessor :storage_backend
    self.storage_backend = :json
    
    cattr_accessor :profile_self
    self.profile_self = false

    attr_accessor :last_stats_flush
    attr_accessor :query_sites
    attr_accessor :profile_data_directory
    
    def self.instance
      Thread.current[:active_record_profiler_collector] ||= Collector.new
    end
    
    def self.profile_self?
      self.profile_self
    end
    
    def self.clear_data
      dir = Dir.new(profile_dir)
      prof_files = dir.entries.select{ |filename| /.prof$/.match(filename) }.map{ |filename| File.join(dir.path, filename) }
      FileUtils.rm(prof_files) if prof_files.size > 0
    end

    def initialize
      @query_sites = {}
      @last_stats_flush = nil
      @profile_data_directory = self.class.profile_dir
    end
    
    def call_location_name(caller_array = nil)
      find_app_call_location(caller_array) || NON_APP_CODE_DESCRIPTION
    end
    
    def record_caller_info(location, seconds, sql)
      return if sql_ignore_pattern.match(sql)
      
      update_counts(location, seconds, 1, sql)
    end
    
    def record_self_info(seconds, name)
      record_caller_info(trim_location(caller.first), seconds, name)
    end
    
    def should_flush_stats?
      self.last_stats_flush ||= Time.now
      return(Time.now > self.last_stats_flush + stats_flush_period)
    end
    
    def flush_query_sites_statistics
      pid = $$
      thread_id = Thread.current.object_id
      flush_time = Time.now
      site_count = self.query_sites.keys.size
      Rails.logger.info("Flushing ActiveRecordProfiler statistics for PID #{pid} at #{flush_time} (#{site_count} sites).")
      
      if (site_count > 0)
        FileUtils.makedirs(self.profile_data_directory)
      
        filename = File.join(self.profile_data_directory, "#{flush_time.strftime(DATETIME_FORMAT)}.#{pid}-#{thread_id}.prof")
        write_file(filename)
        
        # Nuke each value to make sure it can be reclaimed by Ruby
        self.query_sites.keys.each{ |k| self.query_sites[k] = nil }
      end
      self.query_sites = {}
      self.last_stats_flush = flush_time
    end
    
    def aggregate(options = {})
      prefix = options[:prefix]
      compact = options[:compact]
      raise "Cannot compact without a prefix!" if compact && prefix.nil?
      return self.query_sites unless File.exists?(self.profile_data_directory)
      
      dir = Dir.new(self.profile_data_directory)
      now = Time.now
      raw_files_processed = []
      date_regexp = Regexp.new(prefix) if prefix

      dir.each do |filename|
        next unless /.prof$/.match(filename)
        next if date_regexp && ! date_regexp.match(filename)
        # Parse the datetime out of the filename and convert it to localtime
        begin
          file_time = DateTime.strptime(filename, DATETIME_FORMAT)
          file_time = Time.local(file_time.year, file_time.month, file_time.day, file_time.hour, file_time.min)
        rescue Exception => e
          if e.to_s != 'invalid date'
            raise e
          end
        end

        if (file_time.nil? || ((file_time + AGGREGATE_QUIET_PERIOD) < now))
          begin
            update_from_file(File.join(dir.path, filename))
          
            raw_files_processed << filename if file_time    # any files that are already aggregated don't count
          rescue Exception => e
            RAILS_DEFAULT_LOGGER.warn "Unable to read file #{filename}: #{e.message}"
          end
        else
          Rails.logger.info "Skipping file #{filename} because it is too new and may still be open for writing."
        end
      end

      if compact && raw_files_processed.size > 0
        write_file(File.join(dir.path, "#{prefix}.prof"))

        raw_files_processed.each do |filename|
          FileUtils.rm(File.join(dir.path, filename))
        end
      end

      return self.query_sites
    end

    def save_aggregated(date = nil)
      aggregate(:date => date, :compact => true)
    end

    def sorted_locations(sort_field = nil, max_locations = nil)
      sort_field ||= DURATION
      case sort_field
        when LOCATION
          sorted = self.query_sites.keys.sort
        when AVG_DURATION
          sorted = self.query_sites.keys.sort_by{ |k| (self.query_sites[k][DURATION] / self.query_sites[k][COUNT]) }.reverse
        when DURATION, COUNT, LONGEST
          sorted = self.query_sites.keys.sort{ |a,b| self.query_sites[b][sort_field] <=> self.query_sites[a][sort_field] }
        else
          raise "Invalid sort field: #{sort_field}"
      end
      if max_locations && max_locations > 0
        sorted.first(max_locations)
      else
        sorted
      end
    end

    protected

    def find_app_call_location(call_stack)
      call_stack = caller
      while frame = call_stack.shift
        if app_path_pattern.match(frame)
          return trim_location(frame)
        end
      end
      return nil
    end
    
    def trim_location(loc)
      loc.sub(trim_root_path, '')
    end
    
    def update_counts(location, seconds, count, sql, longest = nil)
      longest ||= seconds
      self.query_sites[location] ||= [0.0,0,0,'']
      self.query_sites[location][DURATION] += seconds
      self.query_sites[location][COUNT] += count
      if (longest > self.query_sites[location][LONGEST])
        self.query_sites[location][LONGEST] = longest
        self.query_sites[location][LONGEST_SQL] = sql.to_s
      end
    end
    
    def detect_file_type(filename)
      type = nil
      File.open(filename, "r") do |io|
        first_line = io.readline
        if first_line.match(/^\/\* JSON \*\//)
          type = :json
        end
      end
      return type
    end
    
    def write_file(filename)
      case storage_backend
      when :json
        write_json_file(filename)
      else
        raise "Invalid storage_backend: #{storage_backend}"
      end
    end
    
    def write_json_file(filename)
      File.open(filename, "w") do |file|
        file.puts "/* JSON */"
        file.puts "/* Fields: Duration, Count, Avg. Duration, Max. Duration, Location, Max. Duration SQL */"
        file.puts "["

        first = true
        self.query_sites.each_pair do |location, info|
          if first
            first = false
          else
            file.puts "\n, "
          end
          row = [info[DURATION], info[COUNT], (info[DURATION]/info[COUNT]), info[LONGEST], location, info[LONGEST_SQL]]
          file.print JSON.generate(row)
        end
        file.puts "\n]"
      end
    end
    
    def update_from_file(filename)
      read_file(filename) do |row|
        update_counts(
          row[CSV_LOCATION], row[CSV_DURATION].to_f, row[CSV_COUNT].to_i, row[CSV_LONGEST_SQL], row[CSV_LONGEST].to_f
        )
      end
    end
    
    def read_file(filename)
      file_type = detect_file_type filename
      case file_type
      when :json
        read_json_file(filename) { |row| yield row }
      else
        raise "Unknown profiler data file type for file '#{filename}: #{file_type}"
      end
    end
    
    def read_json_file(filename)
      JSON.load(File.open(filename, "r")).each do |row|
        yield row
      end
    end
  end
end
