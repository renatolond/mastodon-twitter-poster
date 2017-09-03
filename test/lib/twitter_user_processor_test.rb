require 'test_helper'
require 'twitter_user_processor'

class TwitterUserProcessorTest < ActiveSupport::TestCase
  test 'process_user with no error' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago, posting_from_twitter: true)

    TwitterUserProcessor.expects(:get_last_tweets_for_user).times(1).returns(nil)

    Timecop.freeze do
      TwitterUserProcessor::process_user(user)

      assert_equal Time.now, user.twitter_last_check
    end
  end
  test 'process_user with error' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago, posting_from_twitter: true)

    TwitterUserProcessor.expects(:get_last_tweets_for_user).times(1).returns(StandardError)

    Timecop.freeze do
      TwitterUserProcessor::process_user(user)

      assert_equal Time.now, user.twitter_last_check
    end
  end

  test 'user_timeline_options with no last_tweet' do
    user = create(:user_with_mastodon_and_twitter, last_tweet: nil)
    expected_opts = {}

    assert_equal expected_opts, TwitterUserProcessor::user_timeline_options(user)
  end

  test 'user_timeline_options with last tweet' do
    user = create(:user_with_mastodon_and_twitter)
    expected_opts = {since_id: user.last_tweet}

    assert_not_equal Hash.new, TwitterUserProcessor::user_timeline_options(user)
    assert_equal expected_opts, TwitterUserProcessor::user_timeline_options(user)
  end

  test 'get_last_tweets_for_user - check tweet order' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/user_timeline.json?since_id=1000000').to_return(web_fixture('twitter_usertimeline_2tweets.json'))

    tweet_order = [902865452224962560, 902921539997270016]
    TwitterUserProcessor.expects(:process_tweet).at_least(1).returns(nil).then.raises(StandardError).with() {
      |value| value.id == tweet_order.delete_at(0)
    }

    TwitterUserProcessor::get_last_tweets_for_user(user)
  end
  test 'get_last_tweets_for_user - check user params' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/user_timeline.json?since_id=1000000').to_return(web_fixture('twitter_usertimeline_2tweets.json'))

    expected_last_tweet_id = 902865452224962560
    TwitterUserProcessor.expects(:process_tweet).at_least(1).returns(nil).then.raises(StandardError)

    Timecop.freeze do
      TwitterUserProcessor::get_last_tweets_for_user(user)

      assert_equal Time.now, user.twitter_last_check
      assert_equal expected_last_tweet_id, user.last_tweet
    end
  end
  test 'get_last_tweets_for_user - check tweets called' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/user_timeline.json?since_id=1000000').to_return(web_fixture('twitter_usertimeline_2tweets.json'))

    TwitterUserProcessor.expects(:process_tweet).times(2).returns(nil).then.raises(StandardError)

    TwitterUserProcessor::get_last_tweets_for_user(user)
  end
end
