# frozen_string_literal: true

class TootTransformer
  HTTP_REGEX = /(?:http:\/\/)?(?:www\.)?[-a-zA-Z0-9@:%._+\~#=]{2,256}\.[a-z]{2,6}\b(?:[-a-zA-Z0-9@:%\_+.~#?&\/=]*)/
  HTTPS_REGEX = /(?:https:\/\/)[\w.-]+(?:\.[\w.-]+)+[\w\-._~:\/?#\[\]@!\$&'\(\)\*\+,;=.]+/
  IGNORE_CASE_HTTP = Regexp.new(/(?:http:\/\/)/i.to_s + /(?:www\.)?[-a-zA-Z0-9@:%._+\~#=]{2,256}\.[a-z]{2,6}\b(?:[-a-zA-Z0-9@:%\_+.~#?&\/=]*)/.to_s)
  IGNORE_CASE_HTTPS = Regexp.new(/(?:https:\/\/)/i.to_s + /[\w.-]+(?:\.[\w.-]+)+[\w\-._~:\/?#\[\]@!\$&'\(\)\*\+,;=.]+/.to_s)
  MASTODON_USERNAME_REGEX = /@\w+@[\w.-]+(?:\.[\w.-]+)+[\w\-._~:\/?#\[\]@!\$&'\(\)\*\+,;=.]+/
  TWITTER_MENTION_REGEX = /@(\w+)@twitter.com/

  def twitter_max_length
    @twitter_max_length
  end
  def twitter_max_length=(length)
    @twitter_max_length = length
  end

  def initialize(twitter_max_length)
    self.twitter_max_length = twitter_max_length
  end

  def self.media_regex(mastodon_domain)
    mastodon_instance_regex = /#{Regexp.escape(mastodon_domain + "/media/")}([\w-]+)/
    /(#{mastodon_instance_regex}(\s|$)|(\s|^)#{mastodon_instance_regex})/
  end

  def self.replace_uppercase_links(text)
    m = text.scan(IGNORE_CASE_HTTP)
    m2 = text.scan(IGNORE_CASE_HTTPS)
    text = text.dup
    (m + m2).each do |p|
      downcase_p = p.gsub(/http/i, 'http').gsub(/https/i, 'https')
      text.gsub!(p, downcase_p)
    end
    text
  end

  def transform(text, toot_url, mastodon_domain, fix_cross_mention)
    text = self.class.replace_uppercase_links(text)
    text = text.gsub(TWITTER_MENTION_REGEX, '@\1') if fix_cross_mention
    text = text.gsub(TootTransformer::media_regex(mastodon_domain), '')
    text.tr!('*', '＊') # XXX temporary fix for asterisk problem
    transform_rec(text, toot_url, twitter_max_length)
  end

  def transform_rec(text, toot_url, max_length)
    text_without_usernames = text.gsub(MASTODON_USERNAME_REGEX, '')
    https_count, https_length = TootTransformer::count_regex(text_without_usernames, HTTPS_REGEX)
    mod_text = text_without_usernames.gsub(HTTPS_REGEX, '')
    http_count, http_length = TootTransformer::count_regex(mod_text, HTTP_REGEX)
    final_length = (text.length - http_length - https_length) + http_count*TootTransformer::twitter_short_url_length + https_count*TootTransformer::twitter_short_url_length_https
    if final_length <= max_length
      return text
    else
      transform_rec(text.truncate(text.length - [TootTransformer::twitter_short_url_length, TootTransformer::twitter_short_url_length_https].max, separator: /[ \n]/, omission: TootTransformer::suffix+toot_url), toot_url, max_length)
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
