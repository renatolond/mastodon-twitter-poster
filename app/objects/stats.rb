# frozen_string_literal: true

if ENV['STATSD_ENABLED'] == 'true'
  class Stats
    def initialize
      @statsd = Statsd.new(ENV['STATSD_HOST'], ENV['STATSD_PORT'])
    end

    def increment(name)
      @statsd.increment("#{name}")
    end

    def timing(name, ms)
      @statsd.timing(name, ms)
    end

    def time(name, &blk)
      @statsd.time(name, &blk)
    end
  end
else
  class Stats
    def increment(name); end
    def timing(name, ms); end
    def time(name, &blk); end
  end
end
