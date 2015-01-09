# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active-record-profiler/version'

Gem::Specification.new do |spec|
  spec.name          = "active-record-profiler"
  spec.version       = ActiveRecordProfiler::VERSION
  spec.authors       = ["Ben Turner"]
  spec.email         = ["codewrangler@outofcoffee.com"]
  spec.summary       = %q{Enhances ActiveRecord logging and profiles queries}
  spec.description   = <<-EOF
See where each database call is coming from in your code, and get query
profiling to see which queries are taking up the most time in the database.
EOF
  spec.homepage      = "https://github.com/kindjar/active_record_profiler"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rake"
  spec.add_dependency "rails", "~> 4.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "sqlite3"
end
