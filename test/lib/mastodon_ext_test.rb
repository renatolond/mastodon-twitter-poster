require 'test_helper'
require 'mastodon_ext'

class MastodonExtTest < ActiveSupport::TestCase
  def setup
    @client = Mastodon::REST::Client.new(base_url: 'https://mastodon.xyz', bearer_token: '123456')
  end

  test 'Sensitive? in toot with cw' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/7009409').to_return(web_fixture('status7009409.json'))
    status = @client.status(7009409)
    assert status.sensitive?
  end

  test 'Spoiler text in toot with cw' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/7009409').to_return(web_fixture('status7009409.json'))
    status = @client.status(7009409)
    assert_equal 'Test 2', status.spoiler_text
  end

  test 'Sensitive? in regular toot' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6846822').to_return(web_fixture('status6846822.json'))
    status = @client.status(6846822)
    refute status.sensitive?
  end

  test 'Is private? with private toot' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6847302').to_return(web_fixture('status6847302.json'))
    status = @client.status(6847302)
    assert status.is_private?
    refute status.is_public?
  end

  test 'Is unlisted? with unlisted toot' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6847301').to_return(web_fixture('status6847301.json'))
    status = @client.status(6847301)
    assert status.is_unlisted?
    refute status.is_public?
  end

  test 'Is direct? with direct toot' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6847309').to_return(web_fixture('status6847309.json'))
    status = @client.status(6847309)
    assert status.is_direct?
    refute status.is_public?
  end

  test 'Is public? with public toot' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6846822').to_return(web_fixture('status6846822.json'))
    status = @client.status(6846822)

    refute status.is_private?
    refute status.is_unlisted?
    refute status.is_direct?
    assert status.is_public?
  end

  test 'Is reblog? with normal status without reblog' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6846822').to_return(web_fixture('status6846822.json'))
    status = @client.status(6846822)
    refute status.is_reblog?
  end

  test 'Is reblog? with reblog status' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6901463').to_return(web_fixture('status6901463.json'))
    status = @client.status(6901463)
    assert status.is_reblog?
  end

  test 'Is mention? with mention not starting the toot' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6902726').to_return(web_fixture('status6902726.json'))
    status_with_mention = @client.status(6902726)
    refute status_with_mention.is_mention?
  end

  test 'Is mention? with mention starting the toot' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6845573').to_return(web_fixture('mastodon_reply.json'))
    status_starts_with_mention = @client.status(6845573)
    assert status_starts_with_mention.is_mention?
  end

  test 'Text content with media link' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/7213542').to_return(web_fixture('status7213542.json'))
    status_with_media = @client.status(7213542)
    assert_equal 'Test gif https://mastodon.xyz/media/EYkTJVYtr9rvqSC8pxQ', status_with_media.text_content
  end

  test 'Text content with several media links' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/7208347').to_return(web_fixture('status7208347.json'))
    status_with_several_media = @client.status(7208347)
    assert_equal 'Test medias https://mastodon.xyz/media/5_whCONV3Fo8WMrnGVI https://mastodon.xyz/media/_U6j4n6NaZCR8akdaGQ https://mastodon.xyz/media/Gc_lgTmi_r_fNg4wrdk https://mastodon.xyz/media/rZE7yTAbquR-Y-9m1JU', status_with_several_media.text_content
  end

  test 'Text content with mention' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6902726').to_return(web_fixture('status6902726.json'))
    status_with_mention = @client.status(6902726)
    assert_equal 'Test @renatolond@mastodon.xyz', status_with_mention.text_content
  end

  test 'Text content with newline' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6846822').to_return(web_fixture('status6846822.json'))
    status_with_newline = @client.status(6846822)
    assert_equal %q(yet
 <another>
test), status_with_newline.text_content
  end

  test 'Text content with paragraph' do
    stub_request(:get, 'https://mastodon.xyz/api/v1/statuses/6846872').to_return(web_fixture('status6846872.json'))
    status_with_paragraph = @client.status(6846872)
    assert_equal %q(and

one

more

test), status_with_paragraph.text_content
  end
end
