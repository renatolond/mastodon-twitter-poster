require 'datadog/statsd'

class Stats
  def initialize
    @statsd = Datadog::Statsd.new('localhost', 8125)
  end

  def dyno_id
    @dyno_id ||= ENV['DYNO'] || 'unknown'
  end

  def increment(name)
    @statsd.increment(name, tags: ["dyno_id:#{dyno_id}"])
  end
end
