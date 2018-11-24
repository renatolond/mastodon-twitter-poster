# frozen_string_literal: true

require "test_helper"

class StatsTest < ActiveSupport::TestCase
  test "With statsd enabled, call increment calls statsd" do
    statsd_mock = mock()
    statsd_mock.expects(:increment)
    Statsd.expects(:new).returns(statsd_mock)

    Stats.expects(:enabled?).returns(true)

    Stats.new.increment("test")
  end

  test "With statsd disabled, call increment and nothing happens" do
    statsd_mock = mock()
    statsd_mock.expects(:increment).never

    Statsd.expects(:new).never.returns(statsd_mock)

    Stats.expects(:enabled?).returns(false)

    Stats.new.increment("test")
  end
end
