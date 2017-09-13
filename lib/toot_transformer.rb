class TootTransformer
  HTTP_REGEX = /(?:http:\/\/)?[\w.-]+(?:\.[\w.-]+)+[\w\-._~:\/?#\[\]@!\$&'\(\)\*\+,;=.]+/
  HTTPS_REGEX = /(?:https:\/\/)[\w.-]+(?:\.[\w.-]+)+[\w\-._~:\/?#\[\]@!\$&'\(\)\*\+,;=.]+/
  TWITTER_MENTION_REGEX = /@([^@]+)@twitter.com/
  TWITTER_MAX_LENGTH = 140

  def self.media_regex(mastodon_domain)
    mastodon_instance_regex = /#{Regexp.escape(mastodon_domain + "/media/")}([\w-]+)/
    /(#{mastodon_instance_regex}(\s|$)|(\s|^)#{mastodon_instance_regex})/
  end

  def self.transform(text, toot_url, mastodon_domain, fix_cross_mention)
    text.gsub!(TWITTER_MENTION_REGEX, '\1') if fix_cross_mention
    text.gsub!(media_regex(mastodon_domain), '')
    text.gsub!('*', '＊') # XXX temporary fix for asterisk problem
    transform_rec(text, toot_url, TWITTER_MAX_LENGTH)
  end

  def self.transform_rec(text, toot_url, max_length)
    https_count, https_length = count_regex(text, HTTPS_REGEX)
    mod_text = text.gsub(HTTPS_REGEX, '')
    http_count, http_length = count_regex(mod_text, HTTP_REGEX)
    final_length = (text.length - http_length - https_length) + http_count*twitter_short_url_length + https_count*twitter_short_url_length_https
    if final_length <= max_length
      return text
    else
      transform_rec(text.truncate(text.length - [twitter_short_url_length, twitter_short_url_length_https].max, separator: /[ \n]/, omission: suffix+toot_url), toot_url, max_length)
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

  def self.count_regex(text, regex)
    matches = text.scan(regex)
    [matches.count, matches.reduce(0) { |n, s| s.length + n }]
  end
end
