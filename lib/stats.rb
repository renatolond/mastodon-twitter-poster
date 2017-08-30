require 'statsd'

class Stats
  def initialize
    @statsd = Statsd.new('localhost', 8125)
  end

  def dyno_id
    @dyno_id ||= ENV['DYNO'] || 'unknown'
  end

  def increment(name)
    @statsd.increment(name)
  end
end
