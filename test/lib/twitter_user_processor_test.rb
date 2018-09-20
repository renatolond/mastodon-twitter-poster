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

    TwitterUserProcessor.expects(:get_last_tweets_for_user).times(1).raises(StandardError)

    Timecop.freeze do
      assert_raises StandardError do
        TwitterUserProcessor::process_user(user)
      end

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

    assert_raises TwitterUserProcessor::TweetError do
      TwitterUserProcessor::get_last_tweets_for_user(user)
    end
  end
  test 'get_last_tweets_for_user - check user params' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/user_timeline.json?since_id=1000000&tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_usertimeline_2tweets.json'))

    expected_last_tweet_id = 902865452224962560
    twitter_user_processor = mock()
    TwitterUserProcessor.expects(:new).returns(twitter_user_processor).at_least(1)
    twitter_user_processor.expects(:process_tweet).at_least(1).returns(nil).then.raises(StandardError)

    Timecop.freeze do
      assert_raises TwitterUserProcessor::TweetError do
        TwitterUserProcessor::get_last_tweets_for_user(user)
      end

      assert_equal expected_last_tweet_id, user.last_tweet
    end
  end
  test 'get_last_tweets_for_user - check tweets called' do
    user = create(:user_with_mastodon_and_twitter, twitter_last_check: 6.days.ago)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/user_timeline.json?since_id=1000000&tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_usertimeline_2tweets.json'))

    twitter_user_processor = mock()
    TwitterUserProcessor.expects(:new).returns(twitter_user_processor).at_least(1)
    twitter_user_processor.expects(:process_tweet).times(2).returns(nil).then.raises(StandardError)

    assert_raises TwitterUserProcessor::TweetError do
      TwitterUserProcessor::get_last_tweets_for_user(user)
    end
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
    twitter_user_processor.expects(:process_reply).times(0).returns(nil)
    twitter_user_processor.expects(:process_retweet).times(0).returns(nil)
    twitter_user_processor.expects(:process_quote).times(0).returns(nil)
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
    twitter_user_processor.expects(:toot).with(text, [273], false, true, nil).times(1).returns(nil)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/926388565587779584.json?tweet_mode=extended').to_return(web_fixture('twitter_quote.json'))

    t = user.twitter_client.status(926388565587779584, tweet_mode: 'extended')
    text = "What about a quote?\nRT @renatolonddev@twitter.com Hello, world!"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true, nil).times(1).returns(nil)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT - with twitter cw' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt'], twitter_content_warning: 'Twitter stuff')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/926388565587779584.json?tweet_mode=extended').to_return(web_fixture('twitter_quote.json'))

    t = user.twitter_client.status(926388565587779584, tweet_mode: 'extended')
    text = "What about a quote?\nRT @renatolonddev@twitter.com Hello, world!"

    cw = 'Twitter stuff'
    sensitive = true

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], sensitive, true, cw).times(1).returns(nil)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT with cw gets behind cw' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/967415134170894341.json?tweet_mode=extended').to_return(web_fixture('twitter_quote_with_cw.json'))

    stub_request(:get, 'https://video.twimg.com/tweet_video/DWuqqanWkAMtBaq.mp4')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLLQqpiWsAE9aTU.mp4') })

    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(967415134170894341, tweet_mode: 'extended')
    text = "RT @gifsdegatinhos@twitter.com ninguem toca na minha patinha"
    sensitive = true
    cw = 'gatinho!'

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [273], sensitive, true, cw).times(1).returns(nil)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT with link should keep links' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt_with_link'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/926388565587779584.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_quote_with_link_in_quote.json'))

    t = user.twitter_client.status(926388565587779584, tweet_mode: 'extended', include_ext_alt_text: true)
    text = "I'll put a link to pudim in this quote http://pudim.com.br/\nRT @RenatoLondDev@twitter.com test\n\n🐦🔗: https://twitter.com/RenatoLondDev/status/1012728220343525377"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true, nil).times(1).returns(nil)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT with link' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt_with_link'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/926388565587779584.json?tweet_mode=extended').to_return(web_fixture('twitter_quote.json'))

    t = user.twitter_client.status(926388565587779584, tweet_mode: 'extended')
    text = "What about a quote?\nRT @renatolonddev@twitter.com Hello, world!\n\n🐦🔗: https://twitter.com/renatolonddev/status/895751593924210690"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true, nil).times(1).returns(nil)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT: quote with URL gets url replaced' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/936731134456745984.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_quote_with_url.json'))

    t = user.twitter_client.status(936731134456745984, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = []
    sensitive = false
    save_status = true
    cw = nil
    text = "Hey, about that link, let me test a quote!\nRT @renatolonddev@twitter.com A link to http://masto.donte.com.br. You see, I really want this link to become a twitter one :)"
    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, medias, sensitive, save_status, cw).once
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT: quote of a quote gets url replaced' do
    user = create(:user_with_mastodon_and_twitter, quote_options: User.quote_options['quote_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/936734115738669057.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_quote_of_quote.json'))

    t = user.twitter_client.status(936734115738669057, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = []
    sensitive = false
    save_status = true
    cw = nil
    text = "Maybe I have to quote this one, then?\nRT @renatolonddev@twitter.com Hey, about that link, let me test a quote! https://twitter.com/renatolonddev/status/936731074301964288"
    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, medias, sensitive, save_status, cw).once
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT: quote bigger than 500 chars get split in two toots with link in quote with autodetected cw' do
    masto_user = 'beterraba'
    masto_domain = 'comidas.social'
    authorization_masto = build(:authorization_mastodon, uid: "#{masto_user}@#{masto_domain}", masto_domain: masto_domain)
    authorization_twitter = build(:authorization_twitter)
    user = create(:user, authorizations: [authorization_masto, authorization_twitter], quote_options: User.quote_options['quote_post_as_old_rt_with_link'], twitter_quote_visibility: nil)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/1042806820212011008.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_quote_bigger_than_500_chars_with_cw.json'))
    stub_request(:get, 'http://pbs.twimg.com/media/DkFZEoVXgAQs0tJ.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))
    stub_request(:put, "#{user.mastodon_client.base_url}/api/v1/media/273")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(1042806820212011008, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = [273]
    spoiler_text = 'Gatinhos!'

    sensitive = false
    text = "RT @CamisetasCats@twitter.com Vocês já conhecem a nossa Campanha Cats?\nQue tal ajudar adquirindo uma dessas lindas camisetas?\nE tem a opção de envio a 10,00! Confiram lá!\nhttp://bit.ly/campanhacats\n#InternationalCatDay\n\n🐦🔗: https://twitter.com/CamisetasCats/status/1027200357460570113"

    masto_status = mock()
    quote_masto_id = 919819281111
    masto_status.expects(:id).returns(quote_masto_id).once
    user.mastodon_client.expects(:create_status).with(text, media_ids: medias, sensitive: true, spoiler_text: spoiler_text, headers: {"Idempotency-Key" => "#{masto_user}-#{t.quoted_status.id}"}).returns(masto_status)

    text = "Esse é um tweet bem grande que vai ser quebrado em dois quando for pego pelo crosspost. A ideia é que não vai pegar o CN no RT.\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad mi"
    medias = []

    masto_status = mock()
    masto_id = 919819281112
    masto_status.expects(:id).returns(masto_id).twice
    user.mastodon_client.expects(:create_status).with(text, media_ids: medias, sensitive: true, spoiler_text: spoiler_text, in_reply_to_id: quote_masto_id, headers: {"Idempotency-Key" => "#{masto_user}-#{t.id}"}).returns(masto_status)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT: quote bigger than 500 chars get split in two toots with link in quote' do
    masto_user = 'beterraba'
    masto_domain = 'comidas.social'
    authorization_masto = build(:authorization_mastodon, uid: "#{masto_user}@#{masto_domain}", masto_domain: masto_domain)
    authorization_twitter = build(:authorization_twitter)
    user = create(:user, authorizations: [authorization_masto, authorization_twitter], quote_options: User.quote_options['quote_post_as_old_rt_with_link'], twitter_quote_visibility: nil)

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
    stub_request(:put, "#{user.mastodon_client.base_url}/api/v1/media/273")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(936933954241945606, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = [273, 273, 273, 273]

    sensitive = false
    text = "RT @renatolonddev@twitter.com Another attempt, this time a very large tweet, with a lot of words and I'll only include the image at the end.\nThis way, we should go beyond the standard limit and somehow it will not show the link.\nAt least, that's what I'm hoping it's the issue. RTs of long tweets with media.\n\n🐦🔗: https://twitter.com/renatolonddev/status/936747599071207425"

    masto_status = mock()
    quote_masto_id = 919819281111
    masto_status.expects(:id).returns(quote_masto_id).once
    user.mastodon_client.expects(:create_status).with(text, media_ids: medias, headers: {"Idempotency-Key" => "#{masto_user}-#{t.quoted_status.id}"}).returns(masto_status)

    text = "That's the kind of status that gives us problems. It's very annoying a status so big that it will go over the 500 characters of mastodon. But it can happen if you join two big statuses together. Well, in that case, it should not be trying to crosspost it all at once."
    medias = []

    masto_status = mock()
    masto_id = 919819281112
    masto_status.expects(:id).returns(masto_id).twice
    user.mastodon_client.expects(:create_status).with(text, media_ids: medias, in_reply_to_id: quote_masto_id, headers: {"Idempotency-Key" => "#{masto_user}-#{t.id}"}).returns(masto_status)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.process_quote
  end

  test 'process_quote - quote as old style RT: quote bigger than 500 chars get split in two toots with link in quote - with twitter cw' do
    masto_user = 'beterraba'
    masto_domain = 'comidas.social'
    authorization_masto = build(:authorization_mastodon, uid: "#{masto_user}@#{masto_domain}", masto_domain: masto_domain)
    authorization_twitter = build(:authorization_twitter)
    user = create(:user, authorizations: [authorization_masto, authorization_twitter], quote_options: User.quote_options['quote_post_as_old_rt_with_link'], twitter_content_warning: 'Twitter stuff', twitter_quote_visibility: nil)

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
    stub_request(:put, "#{user.mastodon_client.base_url}/api/v1/media/273")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(936933954241945606, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = [273, 273, 273, 273]

    sensitive = true
    text = "RT @renatolonddev@twitter.com Another attempt, this time a very large tweet, with a lot of words and I'll only include the image at the end.\nThis way, we should go beyond the standard limit and somehow it will not show the link.\nAt least, that's what I'm hoping it's the issue. RTs of long tweets with media.\n\n🐦🔗: https://twitter.com/renatolonddev/status/936747599071207425"

    masto_status = mock()
    quote_masto_id = 919819281111
    masto_status.expects(:id).returns(quote_masto_id).once
    user.mastodon_client.expects(:create_status).with(text, sensitive: sensitive, media_ids: medias, spoiler_text: 'Twitter stuff', headers: {"Idempotency-Key" => "#{masto_user}-#{t.quoted_status.id}"}).returns(masto_status)

    text = "That's the kind of status that gives us problems. It's very annoying a status so big that it will go over the 500 characters of mastodon. But it can happen if you join two big statuses together. Well, in that case, it should not be trying to crosspost it all at once."
    medias = []

    masto_status = mock()
    masto_id = 919819281112
    masto_status.expects(:id).returns(masto_id).twice
    user.mastodon_client.expects(:create_status).with(text, sensitive: sensitive, media_ids: medias, in_reply_to_id: quote_masto_id, spoiler_text: 'Twitter stuff', headers: {"Idempotency-Key" => "#{masto_user}-#{t.id}"}).returns(masto_status)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.process_quote
  end
  test 'process_quote - quote as old style RT: quote + twitter cw bigger than 500 chars get split in two toots with link in quote' do
    masto_user = 'beterraba'
    masto_domain = 'comidas.social'
    spoiler_text = 'Twitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuffTwitter stuff'
    authorization_masto = build(:authorization_mastodon, uid: "#{masto_user}@#{masto_domain}", masto_domain: masto_domain)
    authorization_twitter = build(:authorization_twitter)
    user = create(:user, authorizations: [authorization_masto, authorization_twitter], quote_options: User.quote_options['quote_post_as_old_rt_with_link'], twitter_content_warning: spoiler_text, twitter_quote_visibility: nil)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/936734115738669057.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_quote_of_quote.json'))

    t = user.twitter_client.status(936734115738669057, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = []

    sensitive = true
    text = "RT @renatolonddev@twitter.com Hey, about that link, let me test a quote! https://twitter.com/renatolonddev/status/936731074301964288\n\n🐦🔗: https://twitter.com/renatolonddev/status/936731134456745984"

    masto_status = mock()
    quote_masto_id = 919819281111
    masto_status.expects(:id).returns(quote_masto_id).once
    user.mastodon_client.expects(:create_status).with(text, sensitive: sensitive, media_ids: medias, spoiler_text: spoiler_text, headers: {"Idempotency-Key" => "#{masto_user}-#{t.quoted_status.id}"}).returns(masto_status)

    text = "Maybe I have to quote this one, then?"
    medias = []

    masto_status = mock()
    masto_id = 919819281112
    masto_status.expects(:id).returns(masto_id).twice
    user.mastodon_client.expects(:create_status).with(text, sensitive: sensitive, media_ids: medias, in_reply_to_id: quote_masto_id, spoiler_text: spoiler_text, headers: {"Idempotency-Key" => "#{masto_user}-#{t.id}"}).returns(masto_status)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.process_quote
  end
  test 'process_quote - quote as old style RT: quote bigger than 500 chars get split in two toots' do
    masto_user = 'beterraba'
    masto_domain = 'comidas.social'
    authorization_masto = build(:authorization_mastodon, uid: "#{masto_user}@#{masto_domain}", masto_domain: masto_domain)
    authorization_twitter = build(:authorization_twitter)
    user = create(:user, authorizations: [authorization_masto, authorization_twitter], quote_options: User.quote_options['quote_post_as_old_rt'], twitter_quote_visibility: nil)

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
    stub_request(:put, "#{user.mastodon_client.base_url}/api/v1/media/273")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(936933954241945606, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = [273, 273, 273, 273]

    sensitive = false
    text = "RT @renatolonddev@twitter.com Another attempt, this time a very large tweet, with a lot of words and I'll only include the image at the end.\nThis way, we should go beyond the standard limit and somehow it will not show the link.\nAt least, that's what I'm hoping it's the issue. RTs of long tweets with media."

    masto_status = mock()
    quote_masto_id = 919819281111
    masto_status.expects(:id).returns(quote_masto_id).once
    user.mastodon_client.expects(:create_status).with(text, media_ids: medias, headers: {"Idempotency-Key" => "#{masto_user}-#{t.quoted_status.id}"}).returns(masto_status)

    text = "That's the kind of status that gives us problems. It's very annoying a status so big that it will go over the 500 characters of mastodon. But it can happen if you join two big statuses together. Well, in that case, it should not be trying to crosspost it all at once."
    medias = []

    masto_status = mock()
    masto_id = 919819281112
    masto_status.expects(:id).returns(masto_id).twice
    user.mastodon_client.expects(:create_status).with(text, media_ids: medias, in_reply_to_id: quote_masto_id, headers: {"Idempotency-Key" => "#{masto_user}-#{t.id}"}).returns(masto_status)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.process_quote
  end

  test 'process_retweet - do not post RT' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['retweet_do_not_post'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904738384861700096.json?tweet_mode=extended').to_return(web_fixture('twitter_retweet.json'))

    t = user.twitter_client.status(904738384861700096, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).never
    twitter_user_processor.process_retweet
  end

  test 'process_retweet - retweet as old RT with link' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['retweet_post_as_old_rt_with_link'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904738384861700096.json?tweet_mode=extended').to_return(web_fixture('twitter_retweet.json'))

    t = user.twitter_client.status(904738384861700096, tweet_mode: 'extended')
    text = "RT @renatolonddev@twitter.com: test\n\n🐦🔗: https://twitter.com/renatolonddev/status/896020223169581056"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true, nil).times(1).returns(nil)
    twitter_user_processor.process_retweet
  end

  test 'process_retweet - retweet as old RT' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['retweet_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904738384861700096.json?tweet_mode=extended').to_return(web_fixture('twitter_retweet.json'))

    t = user.twitter_client.status(904738384861700096, tweet_mode: 'extended')
    text = "RT @renatolonddev@twitter.com: test"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true, nil).times(1).returns(nil)
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
    stub_request(:put, "#{user.mastodon_client.base_url}/api/v1/media/273")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(935492027109793792, tweet_mode: 'extended', include_ext_alt_text: true)
    medias = [273, 273, 273, 273]
    sensitive = false
    save_status = true
    cw = nil
    text = "RT @renatolonddev@twitter.com: Another attempt, this time a very large tweet, with a lot of words and I'll only include the image at the end.\nThis way, we should go beyond the standard limit and somehow it will not show the link.\nAt least, that's what I'm hoping it's the issue. RTs of long tweets with media."
    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, medias, sensitive, save_status, cw).once
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
    twitter_user_processor.expects(:toot).with(text, [273], false, true, nil).times(1).returns(nil)
    twitter_user_processor.process_retweet
  end

  test 'process_retweet - retweet manual retweet as old RT' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['retweet_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/895311375546888192.json?tweet_mode=extended').to_return(web_fixture('twitter_manual_retweet.json'))

    t = user.twitter_client.status(895311375546888192, tweet_mode: 'extended')
    text = "RT @renatolonddev@twitter.com: Hello, world!"

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true, nil).times(1).returns(nil)
    twitter_user_processor.process_retweet
  end

  test 'process normal tweet' do
    user = create(:user_with_mastodon_and_twitter)
    text = 'Tweet'
    tweet_id = 999999
    medias = []
    possibly_sensitive = false
    save_status = true
    cw = nil

    TweetTransformer.expects(:replace_links).times(1).returns(text)
    tweet = mock()
    tweet.expects(:full_text).returns(text)
    tweet.expects(:possibly_sensitive?).returns(possibly_sensitive)
    tweet.expects(:media).returns([])
    tweet.expects(:urls).returns([])

    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.expects(:toot).with(text, medias, possibly_sensitive, save_status, cw).times(1).returns(nil)
    twitter_user_processor.process_normal_tweet
  end

  test 'process normal tweet - with twitter cw' do
    user = create(:user_with_mastodon_and_twitter, twitter_content_warning: 'Twitter stuff')
    text = 'Tweet'
    tweet_id = 999999
    medias = []
    possibly_sensitive = true
    save_status = true
    cw = 'Twitter stuff'

    TweetTransformer.expects(:replace_links).times(1).returns(text)
    tweet = mock()
    tweet.expects(:full_text).returns(text)
    tweet.expects(:possibly_sensitive?).returns(possibly_sensitive)
    tweet.expects(:media).returns([])
    tweet.expects(:urls).returns([])

    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.expects(:toot).with(text, medias, possibly_sensitive, save_status, cw).times(1).returns(nil)
    twitter_user_processor.process_normal_tweet
  end

  test 'process normal tweet with media' do
    user = create(:user_with_mastodon_and_twitter)
    text = 'Tweet'
    medias = [123]
    tweet_id = 9999999
    possibly_sensitive = false
    save_status = true
    cw = nil

    TweetTransformer.expects(:replace_links).times(1).returns(text)
    tweet = mock()
    tweet.expects(:full_text).returns(text)
    tweet.expects(:possibly_sensitive?).returns(possibly_sensitive)
    tweet.expects(:media).returns([])
    tweet.expects(:urls).returns([])

    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.expects(:find_media).times(1).returns(text)
    twitter_user_processor.expects(:toot).with(text, medias, possibly_sensitive, save_status, cw).times(1).returns(nil)
    twitter_user_processor.instance_variable_set(:@medias, medias)
    twitter_user_processor.process_normal_tweet
  end

  test 'upload video to mastodon and post it together with the toot' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/942479048684400640.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_video.json'))

    stub_request(:head, 'https://video.twimg.com/ext_tw_video/942478818975006720/pu/vid/480x480/qXMcRgrilCk9mDm1.mp4')
      .to_return(:status => 200, :headers => {"content-type"=>["video/mp4"], "content-length"=>["2820542"], :body => nil})
    stub_request(:head, 'https://video.twimg.com/ext_tw_video/942478818975006720/pu/vid/240x240/LWd-ivaT-cP8aOWK.mp4')
      .to_return(:status => 200, :headers => {"content-type"=>["video/mp4"], "content-length"=>["909519"], :body => nil})
    stub_request(:get, 'https://video.twimg.com/ext_tw_video/942478818975006720/pu/vid/480x480/qXMcRgrilCk9mDm1.mp4')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLLQqpiWsAE9aTU.mp4') })

    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(942479048684400640, tweet_mode: 'extended', include_ext_alt_text: true)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert_equal "In case you need a moment of happy in your twitter feed", twitter_user_processor.find_media(t.media, t.full_text.dup)
    assert_equal [273], twitter_user_processor.instance_variable_get(:@medias)
  end

  test 'do not upload video to mastodon if all bitrates bigger than 8mb' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/942479048684400640.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_video.json'))

    stub_request(:head, 'https://video.twimg.com/ext_tw_video/942478818975006720/pu/vid/480x480/qXMcRgrilCk9mDm1.mp4')
      .to_return(:status => 200, :headers => {"content-type"=>["video/mp4"], "content-length"=>["28205420"], :body => nil})
    stub_request(:head, 'https://video.twimg.com/ext_tw_video/942478818975006720/pu/vid/240x240/LWd-ivaT-cP8aOWK.mp4')
      .to_return(:status => 200, :headers => {"content-type"=>["video/mp4"], "content-length"=>["9095190"], :body => nil})

    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(942479048684400640, tweet_mode: 'extended', include_ext_alt_text: true)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert_equal "In case you need a moment of happy in your twitter feed https://twitter.com/LisaAbeyta/status/942479048684400640/video/1", twitter_user_processor.find_media(t.media, t.full_text.dup)
    assert_equal [], twitter_user_processor.instance_variable_get(:@medias)
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
    assert_equal "Test posting image.", twitter_user_processor.find_media(t.media, t.full_text.dup)
    assert_equal [273], twitter_user_processor.instance_variable_get(:@medias)
  end

  test 'image description should be uploaded to mastodon' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/931274037812228097.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_image_with_description.json'))

    stub_request(:get, 'http://pbs.twimg.com/media/DOyMj5JXcAEsOBr.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })

    upload_media_answer = mock()
    upload_media_answer.expects(:id).twice.returns(273)
    user.mastodon_client.expects(:upload_media).returns(upload_media_answer).with() { |file, description|
      description == nil
    }
    user.mastodon_client.expects(:update_media_description).with(273, %q(An image: several triangular signs, similar to the one that indicates priority, one on top of the other. In the bottom of each sign it's written in black letters: TEST.))

    t = user.twitter_client.status(931274037812228097, tweet_mode: 'extended', include_ext_alt_text: true)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert_equal 'Oh!', twitter_user_processor.find_media(t.media, t.full_text)
    assert_equal [273], twitter_user_processor.instance_variable_get(:@medias)
  end

  test 'image description with utf-8 should be uploaded to mastodon' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/948534907998961664.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_image_with_description_with_utf8.json'))

    stub_request(:get, 'http://pbs.twimg.com/media/DSnfUY8XUAAjjXv.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })

    upload_media_answer = mock()
    upload_media_answer.expects(:id).twice.returns(273)
    user.mastodon_client.expects(:upload_media).returns(upload_media_answer).with() { |file, description|
      description == nil
    }
    user.mastodon_client.expects(:update_media_description).with(273, %q(Tést different chárãcters that shoüld be UTF-8. 😉))

    t = user.twitter_client.status(948534907998961664, tweet_mode: 'extended', include_ext_alt_text: true)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert_equal 'Test accented chars in description.', twitter_user_processor.find_media(t.media, t.full_text)
    assert_equal [273], twitter_user_processor.instance_variable_get(:@medias)
  end

  test 'test upload_media retry mechanism' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/948534907998961664.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_image_with_description_with_utf8.json'))

    stub_request(:get, 'http://pbs.twimg.com/media/DSnfUY8XUAAjjXv.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })

    upload_media_answer = mock()
    user.mastodon_client.expects(:upload_media).times(3).raises(HTTP::Error)

    t = user.twitter_client.status(948534907998961664, tweet_mode: 'extended', include_ext_alt_text: true)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert_raises HTTP::Error do
      twitter_user_processor.find_media(t.media, t.full_text)
    end
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
    assert_equal 'Test gif for crossposter', twitter_user_processor.find_media(t.media, t.full_text.dup)
    assert_equal [273], twitter_user_processor.instance_variable_get(:@medias)
  end

  test 'tweet with image and video should not crosspost both' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/1006154061740036101.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_image_and_video.json'))

    stub_request(:get, 'http://pbs.twimg.com/media/DfaTyV2V4AAUo_-.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })
    stub_request(:get, 'https://video.twimg.com/ext_tw_video/1006142294158815232/pu/vid/720x1280/4KL1D3rSrIdi42YM.mp4?tag=3')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLLQqpiWsAE9aTU.mp4') })

    upload_media_answer = mock()
    upload_media_answer.expects(:id).once.returns(273)
    user.mastodon_client.expects(:upload_media).returns(upload_media_answer).with() { |file, description|
      description == nil
    }

    t = user.twitter_client.status(1006154061740036101, tweet_mode: 'extended', include_ext_alt_text: true)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert_equal 'Small hail falling in Stearns Co. #mnwx (Video from Kayla Neussendorfer in Richmond)https://twitter.com/Matt_Brickman/status/1006142590876618754/video/1 http://dlvr.it/QWvwKb', twitter_user_processor.find_media(t.media, TweetTransformer::replace_links(t.full_text, t.urls))
    assert_equal [273], twitter_user_processor.instance_variable_get(:@medias)
  end


  test 'post tweet with images but no text' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.test')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/914920718705594369.json?tweet_mode=extended').to_return(web_fixture('twitter_image2.json'))

    stub_request(:get, 'http://pbs.twimg.com/media/DLJzhYFXcAArwlV.jpg')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })

    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/media")
      .to_return(web_fixture('mastodon_image_post.json'))

    t = user.twitter_client.status(914920718705594369, tweet_mode: 'extended')

    text = '🖼️'

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [273], false, true, nil)
    twitter_user_processor.process_normal_tweet
  end

  test 'tweet with 280 chars' do
    user = create(:user_with_mastodon_and_twitter)
    text = 'Far far away, behind the word mountains, far from the countries Vokalia and Consonantia, there live the blind texts. Separated they live in Bookmarksgrove right at the coast of the Semantics, a large language ocean. A small river named Duden flows by their place and supplies(280)'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/923129550372048896.json?tweet_mode=extended').to_return(web_fixture('twitter_280chars.json'))
    t = user.twitter_client.status(923129550372048896, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true, nil)
    twitter_user_processor.process_normal_tweet
  end

  test 'tweet with escaped chars' do
    user = create(:user_with_mastodon_and_twitter)
    text = '< > 3 # ? ! = $ á é í ó ú ü ä ë ï ö € testing random chars'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/915662689359278080.json?tweet_mode=extended').to_return(web_fixture('twitter_chars.json'))
    t = user.twitter_client.status(915662689359278080, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true, nil)
    twitter_user_processor.process_normal_tweet
  end

  test 'tweet with mention should change into mention with @twitter.com' do
    user = create(:user_with_mastodon_and_twitter)
    text = '@renatolond@twitter.com @ ohnoes@ test @renatolond@twitter.com lond@lond.com.br @renatolond@twitter.com! @renatolond@twitter.com-azul @renatolond@masto.donte.com.br'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/898092629677801472.json?tweet_mode=extended').to_return(web_fixture('twitter_mention2.json'))
    t = user.twitter_client.status(898092629677801472, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true, nil)
    twitter_user_processor.process_normal_tweet
  end

  test 'tweet with dot before mention should change into mention with @twitter.com' do
    user = create(:user_with_mastodon_and_twitter)
    text = '.@renatolond@twitter.com hey, check this out!'

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/936931607960621056.json?tweet_mode=extended').to_return(web_fixture('twitter_mention_with_dot.json'))
    t = user.twitter_client.status(936931607960621056, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with(text, [], false, true, nil)
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
    twitter_user_processor.expects(:toot).with(text, [273, 273, 273, 273], false, true, nil)
    twitter_user_processor.process_normal_tweet
  end

  test 'toot' do
    masto_user = 'beterraba'
    masto_domain = 'comidas.social'
    authorization_masto = build(:authorization_mastodon, uid: "#{masto_user}@#{masto_domain}", masto_domain: masto_domain)
    authorization_twitter = build(:authorization_twitter)
    user = create(:user, authorizations: [authorization_masto, authorization_twitter])

    text = 'Oh yeah!'
    tweet_id = 2938928398392
    masto_id = 98392839283
    medias = []
    possibly_sensitive = false
    save_status = true
    cw = nil
    masto_client = mock()
    user.expects(:mastodon_client).returns(masto_client)
    masto_status = mock()
    masto_status.expects(:id).returns(masto_id).twice
    masto_client.expects(:create_status).with(text, media_ids: medias, headers: {"Idempotency-Key" => "#{masto_user}-#{tweet_id}"}).returns(masto_status)

    tweet = mock()
    tweet.expects(:id).twice.returns(tweet_id)
    tweet.expects(:created_at).returns(Time.now)
    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.toot(text, medias, possibly_sensitive, save_status, cw)
  end

  test 'toot with visibility' do
    masto_user = 'beterraba'
    masto_domain = 'comidas.social'
    authorization_masto = build(:authorization_mastodon, uid: "#{masto_user}@#{masto_domain}", masto_domain: masto_domain)
    authorization_twitter = build(:authorization_twitter)
    user = create(:user, authorizations: [authorization_masto, authorization_twitter], twitter_original_visibility: User.twitter_original_visibilities['private'])

    text = 'Oh yeah!'
    tweet_id = 2938928398392
    masto_id = 98392839283
    medias = []
    possibly_sensitive = false
    save_status = true
    cw = nil
    masto_client = mock()
    user.expects(:mastodon_client).returns(masto_client)
    masto_status = mock()
    masto_status.expects(:id).returns(masto_id).twice
    masto_client.expects(:create_status).with(text, media_ids: medias, visibility: 'private', headers: {"Idempotency-Key" => "#{masto_user}-#{tweet_id}"}).returns(masto_status)

    tweet = mock()
    tweet.expects(:id).twice.returns(tweet_id)
    tweet.expects(:created_at).returns(Time.now)
    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.instance_variable_set(:@type, :original)
    twitter_user_processor.toot(text, medias, possibly_sensitive, save_status, cw)
  end

  test 'toot with cw' do
    masto_user = 'beterraba'
    masto_domain = 'comidas.social'
    authorization_masto = build(:authorization_mastodon, uid: "#{masto_user}@#{masto_domain}", masto_domain: masto_domain)
    authorization_twitter = build(:authorization_twitter)
    user = create(:user, authorizations: [authorization_masto, authorization_twitter])

    text = 'Oh yeah!'
    tweet_id = 2938928398392
    masto_id = 98392839283
    medias = []
    possibly_sensitive = false
    save_status = true
    cw = 'Hot take'
    masto_client = mock()
    user.expects(:mastodon_client).returns(masto_client)
    masto_status = mock()
    masto_status.expects(:id).returns(masto_id).twice
    masto_client.expects(:create_status).with(text, media_ids: medias, spoiler_text: cw, headers: {"Idempotency-Key" => "#{masto_user}-#{tweet_id}"}).returns(masto_status)

    tweet = mock()
    tweet.expects(:id).twice.returns(tweet_id)
    tweet.expects(:created_at).returns(Time.now)
    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.toot(text, medias, possibly_sensitive, save_status, cw)
  end

  test 'toot with medias' do
    masto_user = 'beterraba'
    masto_domain = 'comidas.social'
    authorization_masto = build(:authorization_mastodon, uid: "#{masto_user}@#{masto_domain}", masto_domain: masto_domain)
    authorization_twitter = build(:authorization_twitter)
    user = create(:user, authorizations: [authorization_masto, authorization_twitter])

    text = 'Oh yeah!'
    tweet_id = 9929292
    masto_id = 98392839283
    medias = [123]
    possibly_sensitive = false
    save_status = true
    cw = nil
    masto_client = mock()
    user.expects(:mastodon_client).returns(masto_client)
    masto_status = mock()
    masto_status.expects(:id).returns(masto_id).twice
    masto_client.expects(:create_status).with(text, media_ids: medias, headers: {"Idempotency-Key" => "#{masto_user}-#{tweet_id}"}).returns(masto_status)

    expected_status = Status.new(mastodon_client_id: user.mastodon.mastodon_client_id, tweet_id: tweet_id, masto_id: masto_id)

    tweet = mock()
    tweet.expects(:id).twice.returns(tweet_id)
    tweet.expects(:created_at).returns(Time.now)
    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.toot(text, medias, possibly_sensitive, save_status, cw)

    ignored_attributes = %w(id created_at updated_at)
    assert_equal expected_status.attributes.except(*ignored_attributes), Status.last.attributes.except(*ignored_attributes)
  end

  test 'posted by crossposter - custom link' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/923201403337826304.json?tweet_mode=extended').to_return(web_fixture('twitter_used_crossposter2.json'))
    t = user.twitter_client.status(923201403337826304, tweet_mode: 'extended')
    t.expects(:source).at_least_once.returns(Rails.configuration.x.domain)

    twitter_user_processor = TwitterUserProcessor.new(t, user)
    assert twitter_user_processor.posted_by_crossposter
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
  test 'process_reply - Post reply if self is set and reply is to self, and we know the id but the toot does not exist anymore' do
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
    twitter_user_processor.expects(:toot).never
    twitter_user_processor.expects(:mastodon_status_exist?).with(status.masto_id).returns(false)
    twitter_user_processor.process_reply
    assert status.masto_id, twitter_user_processor.replied_status_id
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
    cw = nil
    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with("I'm talking to myself here.", medias, sensitive, save_status, cw).once
    twitter_user_processor.expects(:mastodon_status_exist?).with(status.masto_id).returns(true)
    twitter_user_processor.process_reply
    assert status.masto_id, twitter_user_processor.replied_status_id
  end
  test 'process_reply - Post reply if self is set and reply is to self, and we know the id - with twitter cw' do
    user = create(:user_with_mastodon_and_twitter, twitter_reply_options: User.twitter_reply_options['twitter_reply_post_self'], twitter_content_warning: 'Twitter stuff')

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/933772488345088001.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_self_reply.json'))

    t = user.twitter_client.status(933772488345088001, tweet_mode: 'extended', include_ext_alt_text: true)
    user_to_reply = t.in_reply_to_user_id
    t.expects(:in_reply_to_user_id).returns(user_to_reply)

    status = create(:status, mastodon_client: user.mastodon.mastodon_client, tweet_id: t.in_reply_to_status_id)

    medias = []
    sensitive = true
    save_status = true
    cw = 'Twitter stuff'
    twitter_user_processor = TwitterUserProcessor.new(t, user)
    twitter_user_processor.expects(:toot).with("I'm talking to myself here.", medias, sensitive, save_status, cw).once
    twitter_user_processor.expects(:mastodon_status_exist?).with(status.masto_id).returns(true)
    twitter_user_processor.process_reply
    assert status.masto_id, twitter_user_processor.replied_status_id
  end

  test 'toot headers' do
    masto_user = 'beterraba'
    masto_domain = 'comidas.social'
    authorization_masto = build(:authorization_mastodon, uid: "#{masto_user}@#{masto_domain}", masto_domain: masto_domain)
    authorization_twitter = build(:authorization_twitter)
    user = create(:user, authorizations: [authorization_masto, authorization_twitter])

    text = 'Oh yeah!'
    tweet_id = 2938928398392
    masto_id = 98392839283
    medias = []
    possibly_sensitive = false
    save_status = true
    cw = nil

    stub_request(:post, "#{user.mastodon_client.base_url}/api/v1/statuses").
  with(body: {"status"=>"Oh yeah!"},
       headers: {'Accept'=>'*/*', 'Authorization'=>'Bearer another-beautiful-token-here', 'Connection'=>'close', 'Content-Length'=>'18', 'Content-Type'=>'application/x-www-form-urlencoded', 'Host'=>user.mastodon_client.base_url['https://'.length..-1], 'User-Agent'=>'MastodonRubyGem/1.1.0', 'Idempotency-Key' => "#{masto_user}-#{tweet_id}"}).
      to_return(web_fixture('mastodon_status_post.json'))

    tweet = mock()
    tweet.expects(:id).twice.returns(tweet_id)
    tweet.expects(:created_at).returns(Time.now)
    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.toot(text, medias, possibly_sensitive, save_status, cw)
  end

  test 'process_quote sets type to quote - quote as old rt' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['quote_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/926388565587779584.json?tweet_mode=extended').to_return(web_fixture('twitter_quote.json'))

    tweet = user.twitter_client.status(926388565587779584, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.expects(:toot)

    twitter_user_processor.process_quote
    assert_equal :quote, twitter_user_processor.instance_variable_get(:@type)
  end
  test 'process_retweet sets type to retweet - retweet as old rt' do
    user = create(:user_with_mastodon_and_twitter, retweet_options: User.retweet_options['retweet_post_as_old_rt'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/904738384861700096.json?tweet_mode=extended').to_return(web_fixture('twitter_retweet.json'))

    tweet = user.twitter_client.status(904738384861700096, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.expects(:toot)

    twitter_user_processor.process_retweet
    assert_equal :retweet, twitter_user_processor.instance_variable_get(:@type)
  end
  test 'process_normal_tweet sets type to original' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/902835613539422209.json?tweet_mode=extended').to_return(web_fixture('twitter_regular_tweet.json'))

    tweet = user.twitter_client.status(902835613539422209, tweet_mode: 'extended')

    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.expects(:toot)

    twitter_user_processor.process_normal_tweet
    assert_equal :original, twitter_user_processor.instance_variable_get(:@type)
  end
  test 'process_reply sets type to original' do
    user = create(:user_with_mastodon_and_twitter, twitter_reply_options: User.twitter_reply_options['twitter_reply_post_self'])

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/933772488345088001.json?tweet_mode=extended&include_ext_alt_text=true').to_return(web_fixture('twitter_self_reply.json'))

    tweet = user.twitter_client.status(933772488345088001, tweet_mode: 'extended', include_ext_alt_text: true)

    user_to_reply = tweet.in_reply_to_user_id
    tweet.expects(:in_reply_to_user_id).returns(user_to_reply)
    status = create(:status, mastodon_client: user.mastodon.mastodon_client, tweet_id: tweet.in_reply_to_status_id)

    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.expects(:mastodon_status_exist?).with(status.masto_id).returns(true)
    twitter_user_processor.expects(:toot)

    twitter_user_processor.process_reply
    assert_equal :original, twitter_user_processor.instance_variable_get(:@type)
  end
  test 'define_visibility - quote' do
    user = create(:user_with_mastodon_and_twitter, twitter_quote_visibility: User.twitter_quote_visibilities['private'])
    tweet = mock()
    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.instance_variable_set(:@type, :quote)

    twitter_user_processor.define_visibility
    assert_equal 'private', twitter_user_processor.instance_variable_get(:@visibility)
  end
  test 'define_visibility - retweet' do
    user = create(:user_with_mastodon_and_twitter, twitter_retweet_visibility: User.twitter_retweet_visibilities['private'])
    tweet = mock()
    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.instance_variable_set(:@type, :retweet)

    twitter_user_processor.define_visibility
    assert_equal 'private', twitter_user_processor.instance_variable_get(:@visibility)
  end
  test 'define_visibility - original' do
    user = create(:user_with_mastodon_and_twitter, twitter_original_visibility: User.twitter_original_visibilities['private'])
    tweet = mock()
    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.instance_variable_set(:@type, :original)

    twitter_user_processor.define_visibility
    assert_equal 'private', twitter_user_processor.instance_variable_get(:@visibility)
  end
  test 'toot longer than 500 chars is ignored' do
    masto_user = 'beterraba'
    masto_domain = 'comidas.social'
    authorization_masto = build(:authorization_mastodon, uid: "#{masto_user}@#{masto_domain}", masto_domain: masto_domain)
    authorization_twitter = build(:authorization_twitter)
    user = create(:user, authorizations: [authorization_masto, authorization_twitter])

    text = 'Bulbasaur Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ivysaur Lorem ipsum dolor sit amet, consectetur adipiscing elit. Venusaur Lorem ipsum dolor sit amet, consectetur adipiscing elit. Charmander Lorem ipsum dolor sit amet, consectetur adipiscing elit. Charmeleon Lorem ipsum dolor sit amet, consectetur adipiscing elit. Charizard Lorem ipsum dolor sit amet, consectetur adipiscing elit. Squirtle Lorem ipsum dolor sit amet, consectetur adipiscing elit. Wartortle Lorem ipsum dolor sit pikachu'
    tweet_id = 2938928398392
    masto_id = 98392839283
    medias = []
    possibly_sensitive = false
    save_status = true
    cw = nil
    user.expects(:mastodon_client).never

    tweet = mock()
    tweet.expects(:id).once.returns(tweet_id)
    tweet.expects(:created_at).never
    twitter_user_processor = TwitterUserProcessor.new(tweet, user)
    twitter_user_processor.toot(text, medias, possibly_sensitive, save_status, cw)
  end
end
