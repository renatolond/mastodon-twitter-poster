unless Rails.env.test?
  twitter_client = Twitter::REST::Client.new do |config|
    config.consumer_key = ENV['TWITTER_CLIENT_ID']
    config.consumer_secret = ENV['TWITTER_CLIENT_SECRET']
  end

  begin
    TootTransformer::twitter_short_url_length = twitter_client.configuration.short_url_length
    TootTransformer::twitter_short_url_length_https = twitter_client.configuration.short_url_length_https
  rescue Twitter::Error::Forbidden, Twitter::Error::BadRequest
    Rails.logger.error { "Missing Twitter credentials" }
    exit
  end
end
