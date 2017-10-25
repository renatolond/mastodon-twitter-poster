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
  test 'process_user without posting from twitter' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago, posting_from_twitter: false)

    TwitterUserProcessor.expects(:get_last_tweets_for_user).times(0)

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

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/user_timeline.json?since_id=1000000&tweet_mode=extended').to_return(web_fixture('twitter_usertimeline_2tweets.json'))

    tweet_order = [902865452224962560, 902921539997270016]
    TwitterUserProcessor.expects(:process_tweet).at_least(1).returns(nil).then.raises(StandardError).with() {
      |value| value.id == tweet_order.delete_at(0)
    }

    TwitterUserProcessor::get_last_tweets_for_user(user)
  end
  test 'get_last_tweets_for_user - check user params' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/user_timeline.json?since_id=1000000&tweet_mode=extended').to_return(web_fixture('twitter_usertimeline_2tweets.json'))

    expected_last_tweet_id = 902865452224962560
    TwitterUserProcessor.expects(:process_tweet).at_least(1).returns(nil).then.raises(StandardError)

    Timecop.freeze do
      TwitterUserProcessor::get_last_tweets_for_user(user)

      assert_equal expected_last_tweet_id, user.last_tweet
    end
  end
  test 'get_last_tweets_for_user - check tweets called' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/user_timeline.json?since_id=1000000&tweet_mode=extended').to_return(web_fixture('twitter_usertimeline_2tweets.json'))

    TwitterUserProcessor.expects(:process_tweet).times(2).returns(nil).then.raises(StandardError)

    TwitterUserProcessor::get_last_tweets_for_user(user)
  end

  test 'process_tweet - retweet' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904738384861700096.json?tweet_mode=extended').to_return(web_fixture('twitter_retweet.json'))

    t = user.twitter_client.status(904738384861700096, tweet_mode: 'extended')

    TwitterUserProcessor.expects(:process_retweet).times(1).returns(nil)

    TwitterUserProcessor::process_tweet(t, user)
  end

  test 'process tweet - manual retweet' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/895311375546888192.json?tweet_mode=extended').to_return(web_fixture('twitter_manual_retweet.json'))

    t = user.twitter_client.status(895311375546888192, tweet_mode: 'extended')

    TwitterUserProcessor.expects(:process_retweet).times(1).returns(nil)

    TwitterUserProcessor::process_tweet(t, user)
  end

  test 'process tweet - reply to tweet' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904746849814360065.json?tweet_mode=extended').to_return(web_fixture('twitter_reply.json'))

    t = user.twitter_client.status(904746849814360065, tweet_mode: 'extended')

    TwitterUserProcessor.expects(:process_reply).times(1).returns(nil)

    TwitterUserProcessor::process_tweet(t, user)
  end
  test 'process tweet - reply to user' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904747662070734848.json?tweet_mode=extended').to_return(web_fixture('twitter_mention.json'))

    t = user.twitter_client.status(904747662070734848, tweet_mode: 'extended')

    TwitterUserProcessor.expects(:process_reply).times(1).returns(nil)

    TwitterUserProcessor::process_tweet(t, user)
  end
  test 'process tweet - normal tweet' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/902835613539422209.json?tweet_mode=extended').to_return(web_fixture('twitter_regular_tweet.json'))

    t = user.twitter_client.status(902835613539422209, tweet_mode: 'extended')

    TwitterUserProcessor.expects(:process_normal_tweet).times(1).returns(nil)

    TwitterUserProcessor::process_tweet(t, user)
  end

  test 'process normal tweet' do
    user = create(:user_with_mastodon_and_twitter)
    text = 'Tweet'
    medias = []
    possibly_sensitive = false

    TwitterUserProcessor.expects(:toot).with(text, medias, possibly_sensitive, user).times(1).returns(nil)
    TwitterUserProcessor.expects(:replace_links).times(1).returns(text)
    tweet = mock()
    tweet.expects(:possibly_sensitive?).returns(possibly_sensitive)
    tweet.expects(:media).returns([])

    TwitterUserProcessor::process_normal_tweet(tweet, user)
  end

  test 'process normal tweet with media' do
    user = create(:user_with_mastodon_and_twitter)
    text = 'Tweet'
    medias = [123]
    possibly_sensitive = false

    TwitterUserProcessor.expects(:toot).with(text, medias, possibly_sensitive, user).times(1).returns(nil)
    TwitterUserProcessor.expects(:replace_links).times(1).returns(text)
    TwitterUserProcessor.expects(:find_media).times(1).returns([text, medias])
    tweet = mock()
    tweet.expects(:possibly_sensitive?).returns(possibly_sensitive)

    TwitterUserProcessor::process_normal_tweet(tweet, user)
  end

  test 'replace links should return regular link instead of shortened one' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/914920793930428416.json?tweet_mode=extended').to_return(web_fixture('twitter_link.json'))

    t = user.twitter_client.status(914920793930428416, tweet_mode: 'extended')

    assert_equal 'Test posting link https://github.com/renatolond/mastodon-twitter-poster :)', TwitterUserProcessor::replace_links(t)
  end

  test 'upload medias to mastodon and post them together with the toot' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/914920718705594369.json?tweet_mode=extended').to_return(web_fixture('twitter_image.json'))

    stub_request(:get, 'http://pbs.twimg.com/media/DLJzhYFXcAArwlV.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })

    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(914920718705594369, tweet_mode: 'extended')

    assert_equal ["Test posting image.", [273], ["https://masto.test/media/Sb_IvtOAk9qDLDwbZC8"]], TwitterUserProcessor::find_media(t, user, t.full_text.dup)
  end

  test 'upload gif to mastodon and post it together with the toot' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/915023144573915137.json?tweet_mode=extended').to_return(web_fixture('twitter_gif.json'))

    stub_request(:get, 'https://video.twimg.com/tweet_video/DLLQqpiWsAE9aTU.mp4')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLLQqpiWsAE9aTU.mp4') })

    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(915023144573915137, tweet_mode: 'extended')

    assert_equal ["Test gif for crossposter", [273], ["https://masto.test/media/Sb_IvtOAk9qDLDwbZC8"]], TwitterUserProcessor::find_media(t, user, t.full_text.dup)
  end

  test 'post tweet with images but no text' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/914920718705594369.json?tweet_mode=extended').to_return(web_fixture('twitter_image2.json'))

    stub_request(:get, 'http://pbs.twimg.com/media/DLJzhYFXcAArwlV.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })

    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(914920718705594369, tweet_mode: 'extended')

    text = 'https://masto.test/media/Sb_IvtOAk9qDLDwbZC8'

    TwitterUserProcessor.expects(:toot).with(text, [273], false, user)
    TwitterUserProcessor::process_normal_tweet(t, user)
  end

  test 'tweet with 280 chars' do
    user = create(:user_with_mastodon_and_twitter)
    text = 'Far far away, behind the word mountains, far from the countries Vokalia and Consonantia, there live the blind texts. Separated they live in Bookmarksgrove right at the coast of the Semantics, a large language ocean. A small river named Duden flows by their place and supplies(280)'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/923129550372048896.json?tweet_mode=extended').to_return(web_fixture('twitter_280chars.json'))
    t = user.twitter_client.status(923129550372048896, tweet_mode: 'extended')

    TwitterUserProcessor.expects(:toot).with(text, [], false, user)
    TwitterUserProcessor::process_normal_tweet(t, user)
  end

  test 'tweet with escaped chars' do
    user = create(:user_with_mastodon_and_twitter)
    text = '< > 3 # ? ! = $ á é í ó ú ü ä ë ï ö € testing random chars'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/915662689359278080.json?tweet_mode=extended').to_return(web_fixture('twitter_chars.json'))
    t = user.twitter_client.status(915662689359278080, tweet_mode: 'extended')

    TwitterUserProcessor.expects(:toot).with(text, [], false, user)
    TwitterUserProcessor::process_normal_tweet(t, user)
  end

  test 'tweet with mention should change into mention with @twitter.com' do
    user = create(:user_with_mastodon_and_twitter)
    text = '@renatolond@twitter.com @ ohnoes@ test @renatolond@twitter.com lond@lond.com.br @renatolond@twitter.com! @renatolond@twitter.com-azul'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/898092629677801472.json?tweet_mode=extended').to_return(web_fixture('twitter_mention2.json'))
    t = user.twitter_client.status(898092629677801472, tweet_mode: 'extended')

    TwitterUserProcessor.expects(:toot).with(text, [], false, user)
    TwitterUserProcessor::process_normal_tweet(t, user)
  end

  test 'tweet with multiple media (but only one link in text)' do
    user = create(:user_with_mastodon_and_twitter)
    text = 'Test medias'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/898629946888814593.json?tweet_mode=extended').to_return(web_fixture('twitter_multiple_media.json'))
    t = user.twitter_client.status(898629946888814593, tweet_mode: 'extended')
    stub_request(:get, 'http://pbs.twimg.com/media/DHiTJq8WAAAJTBe.png')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:get, 'http://pbs.twimg.com/media/DHiTKKpXgAAV5sb.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:get, 'http://pbs.twimg.com/media/DHiTKlyWAAAmZGE.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:get, 'http://pbs.twimg.com/media/DHiTK9_WAAIRzVA.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    TwitterUserProcessor.expects(:toot).with(text, [273, 273, 273, 273], false, user)
    TwitterUserProcessor::process_normal_tweet(t, user)
  end

  test 'toot' do
    user = create(:user_with_mastodon_and_twitter)

    text = 'Oh yeah!'
    medias = []
    possibly_sensitive = false
    masto_client = mock()
    user.expects(:mastodon_client).returns(masto_client)
    masto_client.expects(:create_status).with(text, sensitive: possibly_sensitive, media_ids: medias)

    TwitterUserProcessor::toot(text, medias, possibly_sensitive, user)
  end

  test 'toot with medias' do
    user = create(:user_with_mastodon_and_twitter)

    text = 'Oh yeah!'
    medias = [123]
    possibly_sensitive = false
    masto_client = mock()
    user.expects(:mastodon_client).returns(masto_client)
    masto_client.expects(:create_status).with(text, sensitive: possibly_sensitive, media_ids: medias)

    TwitterUserProcessor::toot(text, medias, possibly_sensitive, user)
  end
end
