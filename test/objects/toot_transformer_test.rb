require 'test_helper'

class TootTransformerTest < ActiveSupport::TestCase
  test 'Count regex without matches' do
    expected_matches = 0
    expected_matches_length = 0
    assert_equal [expected_matches, expected_matches_length], TootTransformer.count_regex('ABCDEF'.freeze, /K/)
  end

  test 'Count regex with matches of same size' do
    expected_matches = 2
    expected_matches_length = 4
    assert_equal [expected_matches, expected_matches_length], TootTransformer.count_regex('ABCDEFAB'.freeze, /AB/)
  end

  test 'Count regex with matches of different size' do
    expected_matches = 3
    expected_matches_length = 7
    assert_equal [expected_matches, expected_matches_length], TootTransformer.count_regex('ABCDEFABAB'.freeze, /ABC?/)
  end

  test 'Transform a text with a username in it and it should be posted in full length' do
    text = "Oh, apparently there's a talk going on in PGConf.eu by @user1@mastodon.social on Mastodon :)\nHope there's a video of it later!".freeze
    expected_text = text

    assert_equal expected_text, TootTransformer.new(140).transform(text, 'https://masto.donte.com.br/@renatolond/1111111', 'https://masto.donte.com.br/', true)
  end

  test 'Transform a text with no links and exactly 280 characters' do
    text = 'Exactly 280 characters Exactly 280 characters Exactly 280 characters Exactly 280 characters Exactly 280 characters Exactly 280 characters Exactly 280 characters Exactly 280 characters Exactly 280 characters Exactly 280 characters Exactly 280 characters Exactly 280 characters :):)'.freeze
    expected_text = text

    assert_equal expected_text, TootTransformer.new(280).transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end

  test 'Regression: pi was being recognized as a URL' do
    text = '3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647093844609550582231725359408128481117450284102701938521105559644622948954930381964428810975665933446128475648233786783165271201909145648566923460348610454326648213393607260249141273724587006606315588174881520920962829254091715364367892590360011330530548820466521384146951941511609433057270365759591953092186117381932611793105118548074462379962749567351885752724891227938183011949'.freeze
    expected_text = '3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647093844609550582231725359408128481117450284102701938521105559644622948954930381964428810975665933446128475648233786783165271201909… https://mastodon.xyz/@renatolond/1111111'

    assert_equal expected_text, TootTransformer.new(280).transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end

  test 'Transform a text with one big link (still inside the 140 char because of twitter short link)' do
    text = ('https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb ' + 'Characters to fill Characters to fill Characters to fill Characters to fill Characters to fill Characters to fill').freeze
    expected_text = text

    assert_equal expected_text, TootTransformer.new(140).transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end

  test 'Transform a text with the max number of urls in it' do
    text = 'https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb '*5 + 'abcd '*4
    expected_text = text

    assert_equal expected_text, TootTransformer.new(140).transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end

  test 'Transform a text with one more than the max number of urls in it' do
    text = ('https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb '*6).freeze
    expected_text = 'https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb https://github.com/rails/rails/blob/cfb1e4dfd8813d3d5c75a15a750b3c53eebdea65/activesupport/lib/active_support/core_ext/string/filters.rb… https://mastodon.xyz/@renatolond/1111111'

    assert_equal expected_text, TootTransformer.new(140).transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end

  test 'Transform text with twitter mention in it' do
    text = 'Hey, @renatolond@twitter.com, how is it going?'.freeze
    expected_text = 'Hey, @renatolond, how is it going?'

    assert_equal expected_text, TootTransformer.new(140).transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end

  test 'Transform text with twitter mention in it and conversion off' do
    text = 'Hey, @renatolond@twitter.com, how is it going?'.freeze
    expected_text = 'Hey, @renatolond@twitter.com, how is it going?'

    assert_equal expected_text, TootTransformer.new(140).transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', false)
  end
  test 'Transform with media links and remove them' do
    text = 'Test medias https://mastodon.xyz/media/5_whCONV3Fo8WMrnGVI https://mastodon.xyz/media/_U6j4n6NaZCR8akdaGQ https://mastodon.xyz/media/Gc_lgTmi_r_fNg4wrdk https://mastodon.xyz/media/rZE7yTAbquR-Y-9m1JU'.freeze
    expected_text = 'Test medias'

    assert_equal expected_text, TootTransformer.new(140).transform(text, 'https://mastodon.xyz/@renatolond/1111111', 'https://mastodon.xyz', true)
  end
  test 'Transform with uppercase links and downcase them' do
    text = 'Is twitter ever going to allow for regular stuff? Http://www.test.com Https://anothertest.com'
    expected_text = 'Is twitter ever going to allow for regular stuff? http://www.test.com https://anothertest.com'

    assert_equal expected_text, TootTransformer.new(140).transform(text, 'https://masto.donte.com.br/@renatolond/1111111', 'https://masto.donte.com.br', true)
  end
end
