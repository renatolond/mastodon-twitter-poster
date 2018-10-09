require 'test_helper'
require 'tweet_transformer'
class TweetTransformerTest < ActiveSupport::TestCase
  test 'replace links should return regular link instead of shortened one' do
    user = create(:user_with_mastodon_and_twitter)

    stub_request(:get, 'https://api.twitter.com/1.1/statuses/show/914920793930428416.json?tweet_mode=extended').to_return(web_fixture('twitter_link.json'))

    t = user.twitter_client.status(914920793930428416, tweet_mode: 'extended')

    assert_equal 'Test posting link https://github.com/renatolond/mastodon-twitter-poster :)', TweetTransformer::replace_links(t.full_text.dup, t.urls)
  end

  test 'regression: tweet with username in the end should return the correct tweet handle' do
    text = 'Test text by @renatolond'

    assert_equal 'Test text by @renatolond@twitter.com', TweetTransformer::replace_mentions(text)
  end

  test 'regression: multiple usernames on twitter seem to be lost when crossposting' do
    text = '@usera @userb @userc @userd hello!'

    assert_equal '@usera@twitter.com @userb@twitter.com @userc@twitter.com @userd@twitter.com hello!', TweetTransformer::replace_mentions(text)
  end

  test 'detect cw: "tw/cw:" format with no space' do
    text = %q(TW/CW: spoiler
Here's my spoiler!)
    cw = 'spoiler'
    filtered_text = "Here's my spoiler!"

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: "tw/cw:" format with weird casing and no space' do
    text = %q(Tw/cW: spoiler
Here's my spoiler!)
    cw = 'spoiler'
    filtered_text = "Here's my spoiler!"

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: "tw/cw:" format with spaces' do
    text = %q(TW/CW:           spoiler
Here's my spoiler!)
    cw = 'spoiler'
    filtered_text = "Here's my spoiler!"

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: "tw, cw," format with spaces' do
    text = %q(TW, CW,           spoiler
Here's my spoiler!)
    cw = 'spoiler'
    filtered_text = "Here's my spoiler!"

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: "cw:" format with spaces' do
    text = %q(CW:           spoiler
Here's my spoiler!)
    cw = 'spoiler'
    filtered_text = "Here's my spoiler!"

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end

  test 'detect cw: with "cw:" and twitter link, make it look like rt' do
    text = 'CW: gatinho! https://twitter.com/gifsdegatinhos/status/967054283299610625'

    cw = 'gatinho!'
    filtered_text = 'RT: https://twitter.com/gifsdegatinhos/status/967054283299610625'

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: "cw " format with no space' do
    text = %q(CW spoiler

Here's my spoiler!
Yet more of the same spoiler)
    cw = 'spoiler'
    filtered_text = %q(Here's my spoiler!
Yet more of the same spoiler)

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: "spoiler " format with no space' do
    text = %q(Spoiler spoiler

Here's my spoiler!
Yet more of the same spoiler)
    cw = 'spoiler'
    filtered_text = %q(Here's my spoiler!
Yet more of the same spoiler)

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: "spoiler: " format with space' do
    text = %q(Spoiler: spoiler

Here's my spoiler!
Yet more of the same spoiler)
    cw = 'spoiler'
    filtered_text = %q(Here's my spoiler!
Yet more of the same spoiler)

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: with "spoiler:" and twitter link, make it look like rt' do
    text = 'Spoiler: gatinho! https://twitter.com/gifsdegatinhos/status/967054283299610625'

    cw = 'gatinho!'
    filtered_text = 'RT: https://twitter.com/gifsdegatinhos/status/967054283299610625'

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: "CN " format with no space' do
    text = %q(CN spoiler

Here's my spoiler!
Yet more of the same spoiler)
    cw = 'spoiler'
    filtered_text = %q(Here's my spoiler!
Yet more of the same spoiler)

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: "CN: " format with space' do
    text = %q(CN: spoiler

Here's my spoiler!
Yet more of the same spoiler)
    cw = 'spoiler'
    filtered_text = %q(Here's my spoiler!
Yet more of the same spoiler)

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: "Contém: " format with space' do
    text = %q(Contém: spoiler

Here's my spoiler!
Yet more of the same spoiler)
    cw = 'spoiler'
    filtered_text = %q(Here's my spoiler!
Yet more of the same spoiler)

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'detect cw: "Contains: " format with space' do
    text = %q(Contains: spoiler

Here's my spoiler!
Yet more of the same spoiler)
    cw = 'spoiler'
    filtered_text = %q(Here's my spoiler!
Yet more of the same spoiler)

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
  test 'ignore "cw:" on the second line' do
    text = %q(Wut!
CW: spoiler
Here's my spoiler!)
    filtered_text = "Wut!
CW: spoiler
Here's my spoiler!"
    cw = nil

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end

  test 'Detect cw: Cw on image-only posts' do
    text = %q(Contains: Some naughty image)

    filtered_text = ''
    cw = 'Some naughty image'

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end

  test 'Detect cw: twitter link on another line should not use rt format' do
    text = "Cw: spoiler\n\nSome text and a link to twitter https://twitter.com/gifsdegatinhos/status/967054283299610625"

    filtered_text = "Some text and a link to twitter https://twitter.com/gifsdegatinhos/status/967054283299610625"
    cw = 'spoiler'

    assert_equal [filtered_text, cw], TweetTransformer::detect_cw(text)
  end
end
