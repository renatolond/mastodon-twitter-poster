class CheckForTweets
  OLDER_THAN_IN_SECONDS = 30
  def self.available_since_last_check
    u = User.where('twitter_last_check < now() - interval \'? seconds\'', OLDER_THAN_IN_SECONDS).order(twitter_last_check: :asc).first
    return unless u.twitter
  end
end
