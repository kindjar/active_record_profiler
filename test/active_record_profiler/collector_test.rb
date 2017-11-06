require 'test_helper.rb'

module ActiveRecordProfiler
  class CollectorTest < ActiveSupport::TestCase
    def setup
      @test_log = StringIO.new
      ActiveRecord::Base.logger = ActiveSupport::Logger.new(@test_log)
    end

    def test_template_path_removes_app_root
      stack_locations = [
        "/var/deploy/current/app/views/users/_row.html.erb:34:in `_app_views_users__row_html_erb___3709568271919910637_70125680359900'",
        "/var/deploy/current/app/views/users/index.html.erb:34:in `_app_views_users_index_html_erb__1553888856029099377_70230900703660'",
        "/var/deploy/rbenv/versions/2.2.4/lib/ruby/gems/2.2.0/gems/actionview-5.1.4/lib/action_view/template.rb:352:in `instrument_render_template'",
      ]
      location = app_collector.call_location_name(stack_locations)

      assert_match(%r{\A/app/views/users/_row.html.erb:34:in `}, location)
    end

    def test_template_path_includes_only_real_path_components
      stack_locations = [
        "/var/deploy/current/app/views/users/_row.html.erb:34:in `_app_views_users__row_html_erb___3709568271919910637_70125680359900'",
        "/var/deploy/current/app/views/users/index.html.erb:34:in `_app_views_users_index_html_erb__1553888856029099377_70230900703660'",
        "/var/deploy/rbenv/versions/2.2.4/lib/ruby/gems/2.2.0/gems/actionview-5.1.4/lib/action_view/template.rb:352:in `instrument_render_template'",
      ]
      location = app_collector.call_location_name(stack_locations)

      assert_match(/in `.*app.*views.*users.*row.*html.*erb'\z/, location)
    end

    private

    def app_collector(app_root: "/var/deploy/current")
      @app_collector ||= Collector.new.tap do |collector|
        collector.app_path_pattern = Regexp.new(Regexp.quote("/var/deploy/current"))
        collector.trim_root_path = "/var/deploy/current"
      end
    end
  end
end
