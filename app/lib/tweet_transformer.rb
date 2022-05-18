# frozen_string_literal: true

class TweetTransformer
  URL_PATTERN = %r{
    (                                                                                                 #   $1 URL
      (https?:\/\/)                                                                                   #   $2 Protocol (required)
      (#{::MastodonRegex[:valid_domain]})                                                              #   $3 Domain(s)
      (?::(#{::MastodonRegex[:valid_port_number]}))?                                                   #   $4 Port number (optional)
      (/#{::MastodonRegex[:valid_url_path]}*)?                                                         #   $5 URL Path and anchor
      (\?#{::MastodonRegex[:valid_url_query_chars]}*#{::MastodonRegex[:valid_url_query_ending_chars]})? #   $6 Query String
    )
  }iox
  def self.replace_links(text, urls)
    urls.each do |u|
      text = text.gsub(u.url.to_s, u.expanded_url.to_s)
    end
    text
  end

  def self.replace_mentions(text)
    twitter_mention_regex = /(\s|^.?|[^A-Za-z0-9_!#\$%&*@＠\/])([@＠][A-Za-z0-9_]+)(?=[^A-Za-z0-9_@＠]|$)/
    text.gsub(twitter_mention_regex, '\1\2@twitter.com')
  end

  def self.detect_cw(text)
    common_format = /(Cont[ée]m:|Contains:|CN:?|Spoiler:?|[CT]W:?|TW\s*[\/,]\s*CW[:,]?|CW\s*[\/,]\s*TW[:,]?)/i
    format = /\A#{common_format}\s+(?<cw>[^\n\r]+)(?:[\n\r]+|\z)(?<text>.*)/im
    rt_format = /\A#{common_format}\s+(?<cw>[^\n\r]+) (?<text>https:\/\/twitter\.com.*)/im

    m = rt_format.match(text)
    return ["RT: #{m[:text]}", m[:cw]] if m

    m = format.match(text)
    return [m[:text], m[:cw]] if m

    [text, nil]
  end

  def self.countable_text(text)
    return "" if text.nil?

    text.dup.tap do |new_text|
      new_text.gsub!(URL_PATTERN, "x" * 23)
    end
  end
end
