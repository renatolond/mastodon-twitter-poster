require 'test_helper'
require 'tweet_transformer'
class TweetTransformerTest < ActiveSupport::TestCase
  test 'replace links should return regular link instead of shortened one' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/914920793930428416.json?tweet_mode=extended').to_return(web_fixture('twitter_link.json'))

    t = user.twitter_client.status(914920793930428416, tweet_mode: 'extended')

    assert_equal 'Test posting link https://github.com/renatolond/mastodon-twitter-poster :)', TweetTransformer::replace_links(t.full_text.dup, t.urls)
  end
end
