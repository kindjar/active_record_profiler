# 1.2.0

* Support for registering alternate editor URL schemes (see README)

# 1.1.0

* Add self-profiling for the logger component
* Prevent calling a logger.add block twice in the unusual case where the block returns a nil message.
* Convert duration in events from milliseconds to seconds (doh!). You'll want to clear old profiler data when upgrading.
* Don't accumulate statistics for queries fulfilled by the CACHE 

# 1.0

* Converted to Rails Engine, with mountable web interface
* Simplified configuration somewhat

# 0.1.0

* Convert from plugin to gem
