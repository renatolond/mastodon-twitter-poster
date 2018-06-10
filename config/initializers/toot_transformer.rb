if Rails.env.test? || File.split($0).last == 'rake'
  Rails.logger.warn { "Using hardcoded values for twitter url length" }
  TootTransformer::twitter_short_url_length = 23
  TootTransformer::twitter_short_url_length_https = 23
else
  twitter_client = Twitter::REST::Client.new do |config|
    config.consumer_key = ENV['TWITTER_CLIENT_ID']
    config.consumer_secret = ENV['TWITTER_CLIENT_SECRET']
  end

  begin
    twitter_config = twitter_client.configuration
    TootTransformer::twitter_short_url_length = twitter_config.short_url_length
    TootTransformer::twitter_short_url_length_https = twitter_config.short_url_length_https
  rescue Twitter::Error::Forbidden, Twitter::Error::BadRequest
    Rails.logger.error { "Missing Twitter credentials" }
    exit
  end
end
