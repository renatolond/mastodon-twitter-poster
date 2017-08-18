class TootTransformer
  HTTP_REGEX = /^(?:http:\/\/)?[\w.-]+(?:\.[\w.-]+)+[\w\-._~:\/?#\[\]@!\$&'\(\)\*\+,;=.]+$/
  HTTPS_REGEX = /^(?:https:\/\/)[\w.-]+(?:\.[\w.-]+)+[\w\-._~:\/?#\[\]@!\$&'\(\)\*\+,;=.]+$/
  TWITTER_MENTION_REGEX = /@([^@]+)@twitter.com/
  TWITTER_MAX_LENGTH = 140

  def self.media_regex(mastodon_domain)
    mastodon_instance_regex = /#{Regexp.escape(mastodon_domain + "/media/")}([\w-]+)/
    /(#{mastodon_instance_regex}(\s|$)|(\s|^)#{mastodon_instance_regex})/
  end

  def self.transform(text, toot_url, mastodon_domain, fix_cross_mention)
    text.gsub!(TWITTER_MENTION_REGEX, '@\1') if fix_cross_mention
    text.gsub!(media_regex(mastodon_domain), '')
    http_count, http_length = count_regex(text, HTTP_REGEX)
    https_count, https_length = count_regex(text, HTTPS_REGEX)
    final_length = (text.length - http_length - https_length) + http_count*twitter_short_url_length + https_count*twitter_short_url_length_https
    if final_length < TWITTER_MAX_LENGTH
      return text
    else
      self.transform_rec(smart_split(text, TWITTER_MAX_LENGTH - suffix.length - twitter_short_url_length_https), toot_url, TWITTER_MAX_LENGTH)
    end
  end

  # XXX cleanup into one method
  def self.transform_rec(text, toot_url, max_length)
    http_count, http_length = count_regex(text, HTTP_REGEX)
    https_count, https_length = count_regex(text, HTTPS_REGEX)
    final_length = (text.length - http_length - https_length) + http_count*twitter_short_url_length + https_count*twitter_short_url_length_https
    if final_length < max_length
      return text + suffix + toot_url
    else
      transform_rec(smart_split(text, max_length - [twitter_short_url_length, twitter_short_url_length_https].max), max_length - [twitter_short_url_length, twitter_short_url_length_https].max)
    end
  end

  def self.twitter_short_url_length=(length)
    @@twitter_short_url_length = length
  end

  def self.twitter_short_url_length_https=(length)
    @@twitter_short_url_length_https = length
  end

  def self.twitter_short_url_length
    @@twitter_short_url_length ||= 23
  end
  def self.twitter_short_url_length_https
    @@twitter_short_url_length_https ||= 23
  end

  def self.suffix
    @@suffix ||= '… '
  end

  # splits the text without breaking words in half
  def self.smart_split(text, max_length)
    content = ''

    first_line = true
    text.each_line do |line|
      line_is = "\n" + line unless first_line
      line_is = line if first_line
      first_line = false

      if(content.length + line_is.length < max_length)
        content += line_is
      else
        content, should_break = split_in_words(content, line, max_length)
        break if should_break
      end
    end

    content
  end

  def self.split_in_words(content, line, max_length)
    first_word = true
    line.split(' ').each do |word|
      word_is = ' ' + word unless first_word
      word_is = word if first_word
      first_word = false

      if (content.length + word_is.length < max_length)
        content += word_is
      else
        return content, true
      end
    end
    return content, false
  end

  def self.count_regex(text, regex)
    matches = text.scan(regex)
    [matches.count, matches.reduce(0) { |n, s| s.length + n }]
  end
end
