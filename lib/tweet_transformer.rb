class TweetTransformer
  def self.replace_links(text, urls)
    urls.each do |u|
      text.gsub!(u.url.to_s, u.expanded_url.to_s)
    end
    text
  end

  def self.replace_mentions(text)
    twitter_mention_regex = /(\s|^.?)(@[A-Za-z0-9_]+)([^A-Za-z0-9_@]|[^@]$)/
    text.gsub(twitter_mention_regex, '\1\2@twitter.com\3')
  end
end
