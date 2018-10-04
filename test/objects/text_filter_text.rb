# frozen_string_literal: true

require 'test_helper'
class TextFilterTest < ActiveSupport::TestCase
  test 'should_filter_coming_from_mastodon? - allow list: does not contain words' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.donte.com.br', masto_word_list: %w[chocolate caramel], masto_block_or_allow_list: 'ALLOW_WITH_WORDS')

    text_filter = TextFilter.new(user)
    assert text_filter.should_filter_coming_from_mastodon?('Oh, this is a bad word: broccoli!', '')
  end

  test 'should_filter_coming_from_mastodon? - allow list: spoiler contain words' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.donte.com.br', masto_word_list: %w[chocolate caramel], masto_block_or_allow_list: 'ALLOW_WITH_WORDS')

    text_filter = TextFilter.new(user)
    refute text_filter.should_filter_coming_from_mastodon?('Oh, this is a bad word: broccoli!', 'chocolate')
  end

  test 'should_filter_coming_from_mastodon? - allow list: text contain words' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.donte.com.br', masto_word_list: %w[chocolate caramel], masto_block_or_allow_list: 'ALLOW_WITH_WORDS')

    text_filter = TextFilter.new(user)
    refute text_filter.should_filter_coming_from_mastodon?('Oh, this is a good word: chocolate!', '')
  end

  test 'should_filter_coming_from_mastodon? - block list: text contain words' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.donte.com.br', masto_word_list: ['broccoli'], masto_block_or_allow_list: 'BLOCK_WITH_WORDS')

    text_filter = TextFilter.new(user)
    assert text_filter.should_filter_coming_from_mastodon?('Oh, this is a bad word: broccoli!', '')
  end

  test 'should_filter_coming_from_mastodon? - block list: does not contain words' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.donte.com.br', masto_word_list: ['broccoli'], masto_block_or_allow_list: 'BLOCK_WITH_WORDS')

    text_filter = TextFilter.new(user)
    refute text_filter.should_filter_coming_from_mastodon?('Oh, this is a good word: chocolate!', '')
  end

  test 'should_filter_coming_from_mastodon? - block list: text partial match should be ignored' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.donte.com.br', masto_word_list: ['mc'], masto_block_or_allow_list: 'BLOCK_WITH_WORDS')

    text_filter = TextFilter.new(user)
    refute text_filter.should_filter_coming_from_mastodon?('Hey, mccartney! Lend me a hand, will ya?', '')
  end
  test 'should_filter_coming_from_mastodon? - block list with phrase' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.donte.com.br', masto_word_list: ['I love you ', 'Good morning, Fediverse'], masto_block_or_allow_list: 'BLOCK_WITH_WORDS')

    text_filter = TextFilter.new(user)
    assert text_filter.should_filter_coming_from_mastodon?('Oh, earth. I love you and I hope we can be together', '')
    refute text_filter.should_filter_coming_from_mastodon?(%(Oh, earth. I love you\nand I hope we can be together), '')
    assert text_filter.should_filter_coming_from_mastodon?("Good morning, fediverse! How y'all doing?", '')
    assert text_filter.should_filter_coming_from_mastodon?(%(Good morning, fediverse\nHow y'all doing?), '')
  end
  test 'should_filter_coming_from_twitter? - allow list: does not contain words' do
    user = create(:user_with_mastodon_and_twitter, twitter_word_list: ['chocolate'], twitter_block_or_allow_list: 'ALLOW_WITH_WORDS')

    text_filter = TextFilter.new(user)
    assert text_filter.should_filter_coming_from_twitter?('Oh, this is a bad word: broccoli!')
  end
  test 'should_filter_coming_from_twitter? - allow list: contain words' do
    user = create(:user_with_mastodon_and_twitter, twitter_word_list: ['chocolate'], twitter_block_or_allow_list: 'ALLOW_WITH_WORDS')

    text_filter = TextFilter.new(user)
    refute text_filter.should_filter_coming_from_twitter?('Oh, this is a good word: chocolate!')
  end
  test 'should_filter_coming_from_twitter? - block list: contain words' do
    user = create(:user_with_mastodon_and_twitter, twitter_word_list: ['broccoli'], twitter_block_or_allow_list: 'BLOCK_WITH_WORDS')

    text_filter = TextFilter.new(user)
    assert text_filter.should_filter_coming_from_twitter?('Oh, this is a bad word: broccoli!')
  end
  test 'should_filter_coming_from_twitter? - block list: does not contain words' do
    user = create(:user_with_mastodon_and_twitter, twitter_word_list: ['broccoli'], twitter_block_or_allow_list: 'BLOCK_WITH_WORDS')

    text_filter = TextFilter.new(user)
    refute text_filter.should_filter_coming_from_twitter?('Oh, this is a good word: chocolate!')
  end
  test 'should_filter_coming_from_twitter? - block list: partial match should be ignored' do
    user = create(:user_with_mastodon_and_twitter, masto_domain: 'masto.donte.com.br', twitter_word_list: ['mc'], twitter_block_or_allow_list: 'BLOCK_WITH_WORDS')

    text_filter = TextFilter.new(user)
    refute text_filter.should_filter_coming_from_twitter?('Hey, mccartney! Lend me a hand, will ya?')
  end
end
