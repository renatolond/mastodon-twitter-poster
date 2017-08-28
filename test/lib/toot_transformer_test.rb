require 'test_helper'
require 'toot_transformer'

class TootTransformerTest < ActiveSupport::TestCase
  test 'Count regex without matches' do
    expected_matches = 0
    expected_matches_length = 0
    assert_equal [expected_matches, expected_matches_length], TootTransformer.count_regex('ABCDEF', /K/)
  end

  test 'Count regex with matches of same size' do
    expected_matches = 2
    expected_matches_length = 4
    assert_equal [expected_matches, expected_matches_length], TootTransformer.count_regex('ABCDEFAB', /AB/)
  end

  test 'Count regex with matches of different size' do
    expected_matches = 3
    expected_matches_length = 7
    assert_equal [expected_matches, expected_matches_length], TootTransformer.count_regex('ABCDEFABAB', /ABC?/)
  end

  test 'Transform a text with no links and exactly 140 characters' do
    text = 'Exactly 140 characters Exactly 140 characters Exactly 140 characters Exactly 140 characters Exactly 140 characters Exactly 140 characters :)'
    expected_text = text

    assert_equal expected_text, TootTransformer::transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end

  test 'Transform a text with one big link (still inside the 140 char because of twitter short link)' do
    text = 'https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb ' + 'Characters to fill Characters to fill Characters to fill Characters to fill Characters to fill Characters to fill'
    expected_text = text

    assert_equal expected_text, TootTransformer::transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end

  test 'Transform a text with the max number of urls in it' do
    text = 'https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb '*5 + 'abcd '*4
    expected_text = text

    assert_equal expected_text, TootTransformer::transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end

  test 'Transform a text with one more than the max number of urls in it' do
    text = 'https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb '*6
    expected_text = 'https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb… https://mastodon.xyz/@renatolond/1111111'

    assert_equal expected_text, TootTransformer::transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end

  test 'Transform text with twitter mention in it' do
    text = 'Hey, @renatolond@twitter.com, how is it going?'
    expected_text = 'Hey, @renatolond, how is it going?'

    assert_equal expected_text, TootTransformer::transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end
  test 'Transform text with twitter mention in it and conversion off' do
    text = 'Hey, @renatolond@twitter.com, how is it going?'
    expected_text = 'Hey, @renatolond@twitter.com, how is it going?'

    assert_equal expected_text, TootTransformer::transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', false)
  end
  test 'Transform with media links and remove them' do
    text = 'Test medias https://mastodon.xyz/media/5_whCONV3Fo8WMrnGVI https://mastodon.xyz/media/_U6j4n6NaZCR8akdaGQ https://mastodon.xyz/media/Gc_lgTmi_r_fNg4wrdk https://mastodon.xyz/media/rZE7yTAbquR-Y-9m1JU'
    expected_text = 'Test medias'

    assert_equal expected_text, TootTransformer::transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end

end
