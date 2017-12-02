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

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/user_timeline.json?since_id=1000000&tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_usertimeline_2tweets.json'))

    tweet_order = [902865452224962560, 902921539997270016]
    twitter_user_processor = mock()
    TwitterUserProcessor.expects(:new).returns(twitter_user_processor).at_least(1).with() {
      |value| value.id == tweet_order.delete_at(0)
    }
    twitter_user_processor.expects(:process_tweet).at_least(1).returns(nil).then.raises(StandardError)

    TwitterUserProcessor::get_last_tweets_for_user(user)
  end
  test 'get_last_tweets_for_user - check user params' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/user_timeline.json?since_id=1000000&tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_usertimeline_2tweets.json'))

    expected_last_tweet_id = 902865452224962560
    twitter_user_processor = mock()
    TwitterUserProcessor.expects(:new).returns(twitter_user_processor).at_least(1)
    twitter_user_processor.expects(:process_tweet).at_least(1).returns(nil).then.raises(StandardError)

    Timecop.freeze do
      TwitterUserProcessor::get_last_tweets_for_user(user)

      assert_equal expected_last_tweet_id, user.last_tweet
    end
  end
  test 'get_last_tweets_for_user - check tweets called' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/user_timeline.json?since_id=1000000&tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_usertimeline_2tweets.json'))

    twitter_user_processor = mock()
    TwitterUserProcessor.expects(:new).returns(twitter_user_processor).at_least(1)
    twitter_user_processor.expects(:process_tweet).times(2).returns(nil).then.raises(StandardError)

    TwitterUserProcessor::get_last_tweets_for_user(user)
  end

  test 'process_tweet - quote' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/926388565587779584.json?tweet_mode=extended').to_return(web_fixture('twitter_quote.json'))

    t = user.twitter_client.status(926388565587779584, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:process_quote).times(1).returns(nil)
    twitter_user_processor.process_tweet
  end

  test 'process_tweet - quote with url' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/936731134456745984.json?tweet_mode=extended').to_return(web_fixture('twitter_quote_with_url.json'))

    t = user.twitter_client.status(936731134456745984, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:process_quote).times(1).returns(nil)
    twitter_user_processor.process_tweet
  end

  test 'process_tweet - quote of quote' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/936734115738669057.json?tweet_mode=extended').to_return(web_fixture('twitter_quote_of_quote.json'))

    t = user.twitter_client.status(936734115738669057, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:process_quote).times(1).returns(nil)
    twitter_user_processor.process_tweet
  end


  test 'process_tweet - retweet' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904738384861700096.json?tweet_mode=extended').to_return(web_fixture('twitter_retweet.json'))

    t = user.twitter_client.status(904738384861700096, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:process_retweet).times(1).returns(nil)
    twitter_user_processor.process_tweet
  end
  test 'process_tweet - retweet with image' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/935492027109793792.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_long_rt_with_media.json'))

    t = user.twitter_client.status(935492027109793792, tweet_mode: 'extended', include_ext_alt_text: true)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:process_retweet).times(1).returns(nil)
    twitter_user_processor.process_tweet
  end

  test 'process tweet - manual retweet' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/895311375546888192.json?tweet_mode=extended').to_return(web_fixture('twitter_manual_retweet.json'))

    t = user.twitter_client.status(895311375546888192, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:process_retweet).times(1).returns(nil)
    twitter_user_processor.process_tweet
  end

  test 'process tweet - reply to tweet' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904746849814360065.json?tweet_mode=extended').to_return(web_fixture('twitter_reply.json'))

    t = user.twitter_client.status(904746849814360065, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:process_reply).times(1).returns(nil)
    twitter_user_processor.process_tweet
  end
  test 'process tweet - reply to user' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904747662070734848.json?tweet_mode=extended').to_return(web_fixture('twitter_mention.json'))

    t = user.twitter_client.status(904747662070734848, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:process_reply).times(1).returns(nil)
    twitter_user_processor.process_tweet
  end
  test 'process tweet - normal tweet' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/902835613539422209.json?tweet_mode=extended').to_return(web_fixture('twitter_regular_tweet.json'))

    t = user.twitter_client.status(902835613539422209, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:posted_by_crossposter).times(1).returns(false)
    twitter_user_processor.expects(:process_normal_tweet).times(1).returns(nil)
    twitter_user_processor.process_tweet
  end

  test 'process tweet - ignore tweet posted by the crossposter' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/902835613539422209.json').to_return(web_fixture('twitter_regular_tweet.json'))

    t = user.twitter_client.status(902835613539422209)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:posted_by_crossposter).times(1).returns(true)
    twitter_user_processor.expects(:process_normal_tweet).times(0).returns(nil)
    twitter_user_processor.process_tweet
  end

  test 'process_quote - do not post quote' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_do_not_post'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/926388565587779584.json?tweet_mode=extended').to_return(web_fixture('twitter_quote.json'))

    t = user.twitter_client.status(926388565587779584, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).times(0)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as link' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_link'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/926388565587779584.json?tweet_mode=extended').to_return(web_fixture('twitter_quote.json'))

    t = user.twitter_client.status(926388565587779584, tweet_mode: 'extended')
    text = 'What about a quote? https://twitter.com/renatolonddev/status/895751593924210690'

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true).times(1).returns(nil)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote with image as old style RT' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/926428711141986309.json?tweet_mode=extended').to_return(web_fixture('twitter_quote_with_img.json'))

    stub_request(:get, 'http://pbs.twimg.com/media/DNDP6u5W4AAHTJ0.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))
    t = user.twitter_client.status(926428711141986309, tweet_mode: 'extended')
    text = "Quote with pic\nRT @renatolonddev@twitter.com Far far away, behind the word mountains, far from the countries Vokalia and Consonantia, there lives one blind text. Separated they live in Bookmarksgrove right at the drops of the Semantics, a large language ocean. A small river named Jujen flows by their place and supplies(280)"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [273], false, true).times(1).returns(nil)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/926388565587779584.json?tweet_mode=extended').to_return(web_fixture('twitter_quote.json'))

    t = user.twitter_client.status(926388565587779584, tweet_mode: 'extended')
    text = "What about a quote?\nRT @renatolonddev@twitter.com Hello, world!"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true).times(1).returns(nil)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT: quote with URL gets url replaced' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/936731134456745984.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_quote_with_url.json'))

    t = user.twitter_client.status(936731134456745984, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = []
    sensitive = false
    save_status = true
    text = "Hey, about that link, let me test a quote!\nRT @renatolonddev@twitter.com A link to http://masto.donte.com.br. You see, I really want this link to become a twitter one :)"
    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, medias, sensitive, save_status).once
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT: quote of a quote gets url replaced' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/936734115738669057.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_quote_of_quote.json'))

    t = user.twitter_client.status(936734115738669057, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = []
    sensitive = false
    save_status = true
    text = "Maybe I have to quote this one, then?\nRT @renatolonddev@twitter.com Hey, about that link, let me test a quote! https://twitter.com/renatolonddev/status/936731074301964288"
    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, medias, sensitive, save_status).once
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT: quote bigger than 500 chars get split in two toots' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/936933954241945606.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_quote_bigger_than_500_chars.json'))
    stub_request(:get, 'http://pbs.twimg.com/media/DP_-xzZXkAcQAkY.png')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:get, 'http://pbs.twimg.com/media/DP_-0-_X0AAda9v.png')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:get, 'http://pbs.twimg.com/media/DP_-3ukXUAIQlR3.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:get, 'http://pbs.twimg.com/media/DP_-88rXkAInWpE.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(936933954241945606, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = [273, 273, 273, 273]

    sensitive = false
    text = "RT @renatolonddev@twitter.com Another attempt, this time a very large tweet, with a lot of words and I'll only include the image at the end.\nThis way, we should go beyond the standard limit and somehow it will not show the link.\nAt least, that's what I'm hoping it's the issue. RTs of long tweets with media."

    masto_status = mock()
    quote_masto_id = 919819281111
    masto_status.expects(:id).returns(quote_masto_id).once
    user.mastodon_client.expects(:create_status).with(text, sensitive: sensitive, media_ids: medias).returns(masto_status)

    text = "That's the kind of status that gives us problems. It's very annoying a status so big that it will go over the 500 characters of mastodon. But it can happen if you join two big statuses together. Well, in that case, it should not be trying to crosspost it all at once."
    medias = []

    masto_status = mock()
    masto_id = 919819281112
    masto_status.expects(:id).returns(masto_id).twice
    user.mastodon_client.expects(:create_status).with(text, sensitive: sensitive, media_ids: medias, in_reply_to_id: quote_masto_id).returns(masto_status)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.process_quote
  end

  test 'process_retweet - retweet as link' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['retweet_post_as_link'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904738384861700096.json?tweet_mode=extended').to_return(web_fixture('twitter_retweet.json'))

    t = user.twitter_client.status(904738384861700096, tweet_mode: 'extended')
    text = "RT: #{t.url}"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true).times(1).returns(nil)
    twitter_user_processor.process_retweet
  end

  test 'process_retweet - do not post RT' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['retweet_do_not_post'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904738384861700096.json?tweet_mode=extended').to_return(web_fixture('twitter_retweet.json'))

    t = user.twitter_client.status(904738384861700096, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).never
    twitter_user_processor.process_retweet
  end

  test 'process_retweet - retweet as old RT' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['retweet_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904738384861700096.json?tweet_mode=extended').to_return(web_fixture('twitter_retweet.json'))

    t = user.twitter_client.status(904738384861700096, tweet_mode: 'extended')
    text = "RT @renatolonddev@twitter.com: test"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true).times(1).returns(nil)
    twitter_user_processor.process_retweet
  end

  test 'process_retweet - retweet as old style RT: retweet of long tweet with images get images posted' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['retweet_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/935492027109793792.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_long_rt_with_media.json'))
    stub_request(:get, 'http://pbs.twimg.com/media/DP_-xzZXkAcQAkY.png')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:get, 'http://pbs.twimg.com/media/DP_-0-_X0AAda9v.png')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:get, 'http://pbs.twimg.com/media/DP_-3ukXUAIQlR3.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:get, 'http://pbs.twimg.com/media/DP_-88rXkAInWpE.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(935492027109793792, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = [273, 273, 273, 273]
    sensitive = false
    save_status = true
    text = "RT @renatolonddev@twitter.com: Another attempt, this time a very large tweet, with a lot of words and I'll only include the image at the end.\nThis way, we should go beyond the standard limit and somehow it will not show the link.\nAt least, that's what I'm hoping it's the issue. RTs of long tweets with media."
    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, medias, sensitive, save_status).once
    twitter_user_processor.process_retweet
  end


  test 'process_retweet - retweet with images as old RT' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['retweet_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/926428678573187072.json?tweet_mode=extended').to_return(web_fixture('twitter_retweet_with_img.json'))

    stub_request(:get, 'http://pbs.twimg.com/media/DM-lvDVWsAAsrCU.png')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))
    t = user.twitter_client.status(926428678573187072, tweet_mode: 'extended')
    text = "RT @renatolonddev@twitter.com:"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [273], false, true).times(1).returns(nil)
    twitter_user_processor.process_retweet
  end

  test 'process_retweet - retweet manual retweet as old RT' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['retweet_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/895311375546888192.json?tweet_mode=extended').to_return(web_fixture('twitter_manual_retweet.json'))

    t = user.twitter_client.status(895311375546888192, tweet_mode: 'extended')
    text = "RT @renatolonddev@twitter.com: Hello, world!"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true).times(1).returns(nil)
    twitter_user_processor.process_retweet
  end

  test 'process normal tweet' do
    user = create(:user_with_mastodon_and_twitter)
    text = 'Tweet'
    tweet_id = 999999
    medias = []
    possibly_sensitive = false
    save_status = true

    TweetTransformer.expects(:replace_links).times(1).returns(text)
    tweet = mock()
    tweet.expects(:full_text).returns(text)
    tweet.expects(:possibly_sensitive?).returns(possibly_sensitive)
    tweet.expects(:media).returns([])
    tweet.expects(:urls).returns([])

    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.expects(:toot).with(text, medias, possibly_sensitive, save_status).times(1).returns(nil)
    twitter_user_processor.process_normal_tweet
  end

  test 'process normal tweet with media' do
    user = create(:user_with_mastodon_and_twitter)
    text = 'Tweet'
    medias = [123]
    tweet_id = 9999999
    possibly_sensitive = false
    save_status = true

    TweetTransformer.expects(:replace_links).times(1).returns(text)
    tweet = mock()
    tweet.expects(:full_text).returns(text)
    tweet.expects(:possibly_sensitive?).returns(possibly_sensitive)
    tweet.expects(:media).returns([])
    tweet.expects(:urls).returns([])

    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.expects(:find_media).times(1).returns([text, medias])
    twitter_user_processor.expects(:toot).with(text, medias, possibly_sensitive, save_status).times(1).returns(nil)
    twitter_user_processor.process_normal_tweet
  end

  test 'upload medias to mastodon and post them together with the toot' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/914920718705594369.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_image.json'))

    stub_request(:get, 'http://pbs.twimg.com/media/DLJzhYFXcAArwlV.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })

    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(914920718705594369, tweet_mode: 'extended', include_ext_alt_text: true)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert_equal ["Test posting image.", [273], ["https://masto.test/media/Sb_IvtOAk9qDLDwbZC8"]], twitter_user_processor.find_media(t.media, t.full_text.dup)
  end

  test 'image description should be uploaded to mastodon' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/931274037812228097.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_image_with_description.json'))

    stub_request(:get, 'http://pbs.twimg.com/media/DOyMj5JXcAEsOBr.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })

    upload_media_answer = mock()
    upload_media_answer.expects(:text_url).returns("https://masto.test/media/Sb_IvtOAk9qDLDwbZC8")
    upload_media_answer.expects(:id).returns(273)
    user.mastodon_client.expects(:upload_media).returns(upload_media_answer).with() { |file, description|
      description == %q(An image: several triangular signs, similar to the one that indicates priority, one on top of the other. In the bottom of each sign it's written in black letters: TEST.)
    }

    t = user.twitter_client.status(931274037812228097, tweet_mode: 'extended', include_ext_alt_text: true)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert_equal ['Oh!', [273], ["https://masto.test/media/Sb_IvtOAk9qDLDwbZC8"]], twitter_user_processor.find_media(t.media, t.full_text)
  end

  test 'upload gif to mastodon and post it together with the toot' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/915023144573915137.json?tweet_mode=extended').to_return(web_fixture('twitter_gif.json'))

    stub_request(:get, 'https://video.twimg.com/tweet_video/DLLQqpiWsAE9aTU.mp4')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLLQqpiWsAE9aTU.mp4') })

    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(915023144573915137, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert_equal ["Test gif for crossposter", [273], ["https://masto.test/media/Sb_IvtOAk9qDLDwbZC8"]], twitter_user_processor.find_media(t.media, t.full_text.dup)
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

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [273], false, true)
    twitter_user_processor.process_normal_tweet
  end

  test 'tweet with 280 chars' do
    user = create(:user_with_mastodon_and_twitter)
    text = 'Far far away, behind the word mountains, far from the countries Vokalia and Consonantia, there live the blind texts. Separated they live in Bookmarksgrove right at the coast of the Semantics, a large language ocean. A small river named Duden flows by their place and supplies(280)'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/923129550372048896.json?tweet_mode=extended').to_return(web_fixture('twitter_280chars.json'))
    t = user.twitter_client.status(923129550372048896, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true)
    twitter_user_processor.process_normal_tweet
  end

  test 'tweet with escaped chars' do
    user = create(:user_with_mastodon_and_twitter)
    text = '< > 3 # ? ! = $ á é í ó ú ü ä ë ï ö € testing random chars'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/915662689359278080.json?tweet_mode=extended').to_return(web_fixture('twitter_chars.json'))
    t = user.twitter_client.status(915662689359278080, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true)
    twitter_user_processor.process_normal_tweet
  end

  test 'tweet with mention should change into mention with @twitter.com' do
    user = create(:user_with_mastodon_and_twitter)
    text = '@renatolond@twitter.com @ ohnoes@ test @renatolond@twitter.com lond@lond.com.br @renatolond@twitter.com! @renatolond@twitter.com-azul @renatolond@masto.donte.com.br'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/898092629677801472.json?tweet_mode=extended').to_return(web_fixture('twitter_mention2.json'))
    t = user.twitter_client.status(898092629677801472, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true)
    twitter_user_processor.process_normal_tweet
  end

  test 'tweet with dot before mention should change into mention with @twitter.com' do
    user = create(:user_with_mastodon_and_twitter)
    text = '.@renatolond@twitter.com hey, check this out!'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/936931607960621056.json?tweet_mode=extended').to_return(web_fixture('twitter_mention_with_dot.json'))
    t = user.twitter_client.status(936931607960621056, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true)
    twitter_user_processor.process_normal_tweet
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

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [273, 273, 273, 273], false, true)
    twitter_user_processor.process_normal_tweet
  end

  test 'toot' do
    user = create(:user_with_mastodon_and_twitter)

    text = 'Oh yeah!'
    tweet_id = 2938928398392
    masto_id = 98392839283
    medias = []
    possibly_sensitive = false
    save_status = true
    masto_client = mock()
    user.expects(:mastodon_client).returns(masto_client)
    masto_status = mock()
    masto_status.expects(:id).returns(masto_id).twice
    masto_client.expects(:create_status).with(text, sensitive: possibly_sensitive, media_ids: medias).returns(masto_status)

    tweet = mock()
    tweet.expects(:id).returns(tweet_id)
    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.toot(text, medias, possibly_sensitive, save_status)
  end

  test 'toot with medias' do
    user = create(:user_with_mastodon_and_twitter)

    text = 'Oh yeah!'
    tweet_id = 9929292
    masto_id = 98392839283
    medias = [123]
    possibly_sensitive = false
    save_status = true
    masto_client = mock()
    user.expects(:mastodon_client).returns(masto_client)
    masto_status = mock()
    masto_status.expects(:id).returns(masto_id).twice
    masto_client.expects(:create_status).with(text, sensitive: possibly_sensitive, media_ids: medias).returns(masto_status)

    expected_status = Status.new(mastodon_client_id: user.mastodon.mastodon_client_id, tweet_id: tweet_id, masto_id: masto_id)

    tweet = mock()
    tweet.expects(:id).returns(tweet_id)
    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.toot(text, medias, possibly_sensitive, save_status)

    ignored_attributes = %w(id created_at updated_at)
    assert_equal expected_status.attributes.except(*ignored_attributes), Status.last.attributes.except(*ignored_attributes)
  end

  test 'posted by crossposter - new app link' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/923201403337826304.json?tweet_mode=extended').to_return(web_fixture('twitter_used_crossposter2.json'))
    t = user.twitter_client.status(923201403337826304, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert twitter_user_processor.posted_by_crossposter
  end
  test 'posted by crossposter - github link' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/896020976940535808.json?tweet_mode=extended').to_return(web_fixture('twitter_used_crossposter.json'))
    t = user.twitter_client.status(896020976940535808, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert twitter_user_processor.posted_by_crossposter
  end
  test 'posted by crossposter - status in the database' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/915662689359278080.json?tweet_mode=extended').to_return(web_fixture('twitter_chars.json'))
    t = user.twitter_client.status(915662689359278080, tweet_mode: 'extended')

    status = create(:status, tweet_id: t.id)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert twitter_user_processor.posted_by_crossposter
  end
  test 'process_reply - Do not post replies' do
    user = create(:user_with_mastodon_and_twitter, twitter_reply_options: User.twitter_reply_options['twitter_reply_do_not_post'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904746849814360065.json?tweet_mode=extended').to_return(web_fixture('twitter_reply.json'))

    t = user.twitter_client.status(904746849814360065, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).never
    twitter_user_processor.process_reply
  end

  test 'process_reply - Do not post reply if self is set and reply is for someone else' do
    user = create(:user_with_mastodon_and_twitter, twitter_reply_options: User.twitter_reply_options['twitter_reply_post_self'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904746849814360065.json?tweet_mode=extended').to_return(web_fixture('twitter_reply.json'))

    t = user.twitter_client.status(904746849814360065, tweet_mode: 'extended')
    user_to_reply = t.in_reply_to_user_id
    t.expects(:in_reply_to_user_id).returns(user_to_reply)

    Status.expects(:find_by).never

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).never
    twitter_user_processor.process_reply
  end

  test 'process_reply - Do not post reply if self is set and reply is to self, but we don\'t know the id' do
    user = create(:user_with_mastodon_and_twitter, twitter_reply_options: User.twitter_reply_options['twitter_reply_post_self'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/933772488345088001.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_self_reply.json'))

    t = user.twitter_client.status(933772488345088001, tweet_mode: 'extended', include_ext_alt_text: true)
    user_to_reply = t.in_reply_to_user_id
    t.expects(:in_reply_to_user_id).returns(user_to_reply)

    Status.expects(:find_by).once

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).never
    twitter_user_processor.process_reply
  end
  test 'process_reply - Post reply if self is set and reply is to self, and we know the id' do
    user = create(:user_with_mastodon_and_twitter, twitter_reply_options: User.twitter_reply_options['twitter_reply_post_self'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/933772488345088001.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_self_reply.json'))

    t = user.twitter_client.status(933772488345088001, tweet_mode: 'extended', include_ext_alt_text: true)
    user_to_reply = t.in_reply_to_user_id
    t.expects(:in_reply_to_user_id).returns(user_to_reply)

    status = create(:status, mastodon_client: user.mastodon.mastodon_client, tweet_id: t.in_reply_to_status_id)

    medias = []
    sensitive = false
    save_status = true
    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with("I'm talking to myself here.", medias, sensitive, save_status).once
    twitter_user_processor.process_reply
    assert status.masto_id, twitter_user_processor.replied_status_id
  end
end
