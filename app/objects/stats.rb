# frozen_string_literal: true

class Stats
  def self.enabled?
    @@enabled = ENV["STATSD_ENABLED"] == "true"
  end

  def initialize
    if self.class.enabled?
      @statsd = Statsd.new(ENV["STATSD_HOST"], ENV["STATSD_PORT"])
    end
  end

  def increment(name)
    @statsd&.increment("#{name}")
  end

  def timing(name, ms)
    @statsd&.timing(name, ms)
  end

  def time(name, &blk)
    if @statsd
      @statsd.time(name, &blk)
    else
      blk.call
    end
  end
end
