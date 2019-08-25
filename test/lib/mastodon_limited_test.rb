# frozen_string_literal: true

require "test_helper"
require "mastodon_limited"

class MastodonLimitedTest < ActiveSupport::TestCase
  test "without blocked or allowed domains, should call super" do
    mastodon_limited = OmniAuth::Strategies::MastodonLimited.new("foo")
    mastodon_limited.expects(:blocked_domains).returns([])
    mastodon_limited.expects(:allowed_domains).returns(nil)
    mastodon_limited.expects(:identifier).returns("test@some.domain")
    OmniAuth::Strategies::Mastodon.any_instance.expects(:start_oauth).once
    mastodon_limited.start_oauth
  end

  test "with blocked domains, using a good domain, should call super" do
    mastodon_limited = OmniAuth::Strategies::MastodonLimited.new("foo")
    mastodon_limited.expects(:blocked_domains).at_least_once.returns(["a.bad.domain"])
    mastodon_limited.expects(:identifier).returns("test@some.domain")
    OmniAuth::Strategies::Mastodon.any_instance.expects(:start_oauth).once
    mastodon_limited.start_oauth
  end

  test "with blocked domains, using a bad domain, should fail" do
    mastodon_limited = OmniAuth::Strategies::MastodonLimited.new("foo")
    mastodon_limited.expects(:blocked_domains).twice.returns(["a.bad.domain"])
    mastodon_limited.expects(:allowed_domains).never
    mastodon_limited.expects(:identifier).returns("test@a.bad.domain")
    OmniAuth::Strategies::Mastodon.any_instance.expects(:start_oauth).never
    OmniAuth::Strategies::Mastodon.any_instance.expects(:fail!).once
    mastodon_limited.start_oauth
  end

  test "with blocked domains, using a bad sub-domain, should fail" do
    mastodon_limited = OmniAuth::Strategies::MastodonLimited.new("foo")
    mastodon_limited.expects(:blocked_domains).twice.returns(["bad.domain"])
    mastodon_limited.expects(:allowed_domains).never
    mastodon_limited.expects(:identifier).returns("test@a.bad.domain")
    OmniAuth::Strategies::Mastodon.any_instance.expects(:start_oauth).never
    OmniAuth::Strategies::Mastodon.any_instance.expects(:fail!).once
    mastodon_limited.start_oauth
  end

  test "with allowed domain, using the allowed domain, should call super" do
    mastodon_limited = OmniAuth::Strategies::MastodonLimited.new("foo")
    mastodon_limited.expects(:blocked_domains).at_least_once.returns(["a.bad.domain"])
    mastodon_limited.expects(:allowed_domains).twice.returns(["a.good.domain"])
    mastodon_limited.expects(:identifier).returns("test@a.good.domain")
    OmniAuth::Strategies::Mastodon.any_instance.expects(:start_oauth).once
    mastodon_limited.start_oauth
  end

  test "with allowed domain, using other domain, should call super" do
    mastodon_limited = OmniAuth::Strategies::MastodonLimited.new("foo")
    mastodon_limited.expects(:blocked_domains).at_least_once.returns(["a.bad.domain"])
    mastodon_limited.expects(:allowed_domains).at_least_once.returns(["a.good.domain"])
    mastodon_limited.expects(:identifier).returns("test@some.domain")
    OmniAuth::Strategies::Mastodon.any_instance.expects(:start_oauth).never
    OmniAuth::Strategies::Mastodon.any_instance.expects(:fail!).once
    mastodon_limited.start_oauth
  end

  test "blocked domains" do
    ENV.expects(:[]).at_least_once.returns(nil)
    mastodon_limited = OmniAuth::Strategies::MastodonLimited.new("foo")
    assert_equal ["gab.com", "gab.ai", "kiwifarms.cc", "kiwifarms.is", "kiwifarms.net"], mastodon_limited.blocked_domains
  end
end
