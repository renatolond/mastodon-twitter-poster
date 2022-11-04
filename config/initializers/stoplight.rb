# frozen_string_literal: true

require "redis"

redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/2"))
data_store = Stoplight::DataStore::Redis.new(redis)
Stoplight::Light.default_data_store = data_store
