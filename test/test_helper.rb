ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

require 'test/unit'
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))

ActiveRecordProfiler::Collector.profile_environments = %w( test )
ActiveRecordProfiler::Collector.app_path_pattern = Regexp.new(Regexp.quote("/test/"))

$test_config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))

load(File.dirname(__FILE__) + "/schema.rb")

# Once the plugin is installed, don't want to run init.rb again...
# require File.dirname(__FILE__) + '/../init.rb'

class DummyLog < ActiveRecord::Base
end
