require 'test_helper'
require 'mastodon_user_processor'

class MastodonUserProcessorTest < ActiveSupport::TestCase
  test 'boost as link' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6901463').to_return(web_fixture('mastodon_boost.json'))
    t = user.mastodon_client.status(6901463)
    text = "Boosted: #{t.url}"

    mastodon_user_processor = MastodonUserProcessor.new(t, user)
    mastodon_user_processor.expects(:should_post).returns(true)
    mastodon_user_processor.expects(:tweet).with(text).times(1).returns(nil)
    mastodon_user_processor.boost_as_link
  end

  test 'process toot - direct toot' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/7706182').to_return(web_fixture('mastodon_direct_toot.json'))
    t = user.mastodon_client.status(7706182)

    mastodon_user_processor = MastodonUserProcessor.new(t, user)
    mastodon_user_processor.expects(:process_boost).never
    mastodon_user_processor.expects(:process_reply).never
    mastodon_user_processor.expects(:process_mention).never
    mastodon_user_processor.expects(:process_normal_toot).never
    mastodon_user_processor.expects(:posted_by_crossposter).returns(false)

    mastodon_user_processor.process_toot
  end

  test 'process toot - boost' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6901463').to_return(web_fixture('mastodon_boost.json'))
    t = user.mastodon_client.status(6901463)

    mastodon_user_processor = MastodonUserProcessor.new(t, user)
    mastodon_user_processor.expects(:posted_by_crossposter).returns(false)
    mastodon_user_processor.expects(:process_reply).never
    mastodon_user_processor.expects(:process_mention).never
    mastodon_user_processor.expects(:process_normal_toot).never
    mastodon_user_processor.expects(:process_boost).once

    mastodon_user_processor.process_toot
  end

  test 'process toot - reply' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6845573').to_return(web_fixture('mastodon_reply.json'))
    t = user.mastodon_client.status(6845573)

    mastodon_user_processor = MastodonUserProcessor.new(t, user)
    mastodon_user_processor.expects(:posted_by_crossposter).returns(false)
    mastodon_user_processor.expects(:process_boost).never
    mastodon_user_processor.expects(:process_mention).never
    mastodon_user_processor.expects(:process_normal_toot).never
    mastodon_user_processor.expects(:process_reply).once

    mastodon_user_processor.process_toot
  end

  test 'process toot - mention' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6846109').to_return(web_fixture('mastodon_mention.json'))
    t = user.mastodon_client.status(6846109)

    mastodon_user_processor = MastodonUserProcessor.new(t, user)
    mastodon_user_processor.expects(:posted_by_crossposter).returns(false)
    mastodon_user_processor.expects(:process_boost).never
    mastodon_user_processor.expects(:process_reply).never
    mastodon_user_processor.expects(:process_normal_toot).never
    mastodon_user_processor.expects(:process_mention).once

    mastodon_user_processor.process_toot
  end

  test 'process toot - posted by the crossposter' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/98894252337740537').to_return(web_fixture('mastodon_crossposted_toot.json'))
    t = user.mastodon_client.status(98894252337740537)

    mastodon_user_processor = MastodonUserProcessor.new(t, user)
    mastodon_user_processor.expects(:process_boost).never
    mastodon_user_processor.expects(:process_reply).never
    mastodon_user_processor.expects(:process_mention).never
    mastodon_user_processor.expects(:process_normal_toot).never
    mastodon_user_processor.process_toot
  end

  test 'process normal toot' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')
    text = 'Test.'

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/7692449').to_return(web_fixture('mastodon_toot.json'))
    t = user.mastodon_client.status(7692449)

    toot_transformer = mock()
    TootTransformer.expects(:new).with(280).returns(toot_transformer)
    toot_transformer.expects(:transform).with(t.text_content, t.url, 'https://mastodon.xyz', false).returns(t.text_content)
    mastodon_user_processor = MastodonUserProcessor.new(t, user)
    mastodon_user_processor.expects(:should_post).returns(true)
    mastodon_user_processor.expects(:tweet).with(text, {}).times(1).returns(nil)
    mastodon_user_processor.expects(:toot_content_to_post).returns(t.text_content)
    mastodon_user_processor.expects(:upload_media).returns({})

    mastodon_user_processor.process_normal_toot
  end

  test 'tweet' do
    user = create(:user_with_mastodon_and_twitter)

    text = 'Oh yeah!'
    tweet_id = 926053415448469505
    masto_id = 98392839283
    medias = []
    possibly_sensitive = false
    expected_status = Status.new(mastodon_client_id: user.mastodon.mastodon_client_id, tweet_id: tweet_id, masto_id: masto_id)

    stub_request(:post, 'https://api.twitter.com/1.1/statuses/update.json').to_return(web_fixture('twitter_update.json'))
    toot = mock()
    toot.expects(:id).returns(masto_id)
    MastodonUserProcessor.new(toot, user).tweet(text)
    ignored_attributes = %w(id created_at updated_at)
    assert_equal expected_status.attributes.except(*ignored_attributes), Status.last.attributes.except(*ignored_attributes)
  end

  test 'posted by the crossposter - boost not posted' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6901463').to_return(web_fixture('mastodon_boost.json'))
    t = user.mastodon_client.status(6901463)

    refute MastodonUserProcessor.new(t, user).posted_by_crossposter
  end
  test 'posted by the crossposter - not posted' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/7692449').to_return(web_fixture('mastodon_toot.json'))
    t = user.mastodon_client.status(7692449)

    refute MastodonUserProcessor.new(t, user).posted_by_crossposter
  end
  test 'posted by the crossposter - link match' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/98894252337740537').to_return(web_fixture('mastodon_crossposted_toot.json'))
    t = user.mastodon_client.status(98894252337740537)

    assert MastodonUserProcessor.new(t, user).posted_by_crossposter
  end
  test 'posted by the crossposter - status in the database' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/7692449').to_return(web_fixture('mastodon_toot.json'))
    t = user.mastodon_client.status(7692449)

    status = create(:status, masto_id: t.id, mastodon_client: user.mastodon.mastodon_client)

    assert MastodonUserProcessor.new(t, user).posted_by_crossposter
  end

  test 'Recover from too big status' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    text = 'One morning, when Gregor Samsa woke from troubled dreams, he found himself transformed in his bed into a horrible vermin. He lay on his armour-like back, and if he lifted     his head a little he could see his brown belly, slightly domed and… https://mastodon.xyz/@renatolonddev/98974469120828056'

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/98974469120828056').to_return(web_fixture('masto_500_chars.json'))
    t = user.mastodon_client.status(98974469120828056)

    stub_big_post = stub_request(:post, 'https://api.twitter.com/1.1/statuses/update.json').with { |request| request.body == 'status=One+morning%2C+when+Gregor+Samsa+woke+from+troubled+dreams%2C+he+found+himself+transformed+in+his+bed+into+a+horrible+vermin.+He+lay+on+his+armour-like+back%2C+and+if+he+lifted+++++his+head+a+little+he+could+see+his+brown+belly%2C+slightly+domed+and%E2%80%A6+https%3A%2F%2Fmastodon.xyz%2F%40renatolonddev%2F98974469120828056'}.to_return(web_fixture('twitter_update_too_big.json'))
    stub_request(:post, 'https://api.twitter.com/1.1/statuses/update.json').with { |request| request.body == 'status=One+morning%2C+when+Gregor+Samsa+woke+from+troubled+dreams%2C+he+found+himself+transformed+in+his+bed+into+a%E2%80%A6+https%3A%2F%2Fmastodon.xyz%2F%40renatolonddev%2F98974469120828056' }.to_return(web_fixture('twitter_update.json'))

    mastodon_user_processor = MastodonUserProcessor.new(t, user)
    mastodon_user_processor.tweet(text)

    assert_requested(stub_big_post)
  end

  test 'upload images' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/98889131472877168').to_return(web_fixture('mastodon_image.json'))
    t = user.mastodon_client.status(98889131472877168)

    stub_request(:get, 'https://6-28.mastodon.xyz/media_attachments/files/000/966/280/original/488f8918c5035959.png')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })

    user.twitter_client.expects(:upload).returns('9283923').with() { |file, options|
      options == {:media_type => "image/png", :media_category => "tweet_image"}
    }

    mastodon_user_processor = MastodonUserProcessor.new(t, user)
    mastodon_user_processor.upload_media(t.media_attachments)
  end
  test 'image description should be uploaded to twitter' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'mastodon.xyz')

    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/99016225502890297').to_return(web_fixture('mastodon_image_with_description.json'))
    t = user.mastodon_client.status(99016225502890297)

    stub_request(:get, 'https://6-28.mastodon.xyz/media_attachments/files/001/076/793/original/fe104e1dd1cab077.png')
      .to_return(:status => 200, :body => lambda { |request| File.new(Rails.root + 'test/webfixtures/DLJzhYFXcAArwlV.jpg') })

    user.twitter_client.expects(:upload).returns('222917').with() { |file, options|
      options == {:media_type => "image/png", :media_category => "tweet_image"}
    }

    stub_request(:post, "https://api.twitter.com/1.1/media/metadata/create.json").
      with(body: "{\"alt_text\":{\"text\":\"An image: a triangular sign, similar to the one indicating priority, saying in big letters \\\"test\\\"\"},\"media_id\":\"222917\"}")
      .to_return(:status => 200)

    mastodon_user_processor = MastodonUserProcessor.new(t, user)
    mastodon_user_processor.upload_media(t.media_attachments)
  end
end
