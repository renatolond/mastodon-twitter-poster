require 'statsd'

class Stats
  def initialize
    @statsd = Statsd.new('127.0.0.1', 8125)
  end

  def dyno_id
    @dyno_id ||= ENV['DYNO'] || 'unknown'
  end

  def increment(name)
    @statsd.increment("#{name}")
  end

  def timing(name, ms)
    @statsd.timing(name, ms)
  end
end
