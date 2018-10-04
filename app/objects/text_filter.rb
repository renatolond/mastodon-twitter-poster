# frozen_string_literal: true

class TextFilter
  def initialize(user)
    @user = user
  end

  def should_filter_coming_from_mastodon?(text, spoiler_text)
    return true if (user.masto_using_blocklist && content_on_masto_word_list(text, spoiler_text)) ||
                   (user.masto_using_allowlist && !content_on_masto_word_list(text, spoiler_text))

    false
  end

  def should_filter_coming_from_twitter?(text)
    return true if (user.twitter_using_blocklist && content_on_twitter_word_list(text)) ||
                   (user.twitter_using_allowlist && !content_on_twitter_word_list(text))

    false
  end

  private

  attr_reader :user

  def masto_words_regex
    @masto_words_regex ||= build_regex user.masto_word_list
  end

  def twitter_words_regex
    @twitter_words_regex ||= build_regex user.twitter_word_list
  end

  def build_regex(word_list)
    processed_word_list = word_list.map do |word|
      sb = word.match?(/\A[[:word:]]/) ? '\b' : ''
      eb = word.match?(/[[:word:]]\z/) ? '\b' : ''
      /(?mix:#{sb}#{Regexp.escape(word)}#{eb})/
    end
    Regexp.union(*processed_word_list)
  end

  def content_on_masto_word_list(text, spoiler_text)
    text.match?(masto_words_regex) || spoiler_text.match?(masto_words_regex)
  end

  def content_on_twitter_word_list(text)
    text.match?(twitter_words_regex)
  end
end
