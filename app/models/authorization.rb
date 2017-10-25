class Authorization < ApplicationRecord
  belongs_to :user, inverse_of: :authorizations, required: true
  belongs_to :mastodon_client, required: false

  default_scope { order('id asc') }

  def fetch_profile_data
    if self.provider == 'twitter'
      user.save_last_tweet_id
    elsif self.provider == 'mastodon'
      self.mastodon_client = MastodonClient.find_by_domain(mastodon_domain) if self.new_record?
      if self.mastodon_client.nil?
        Rails.logger.error { "Could not find MastodonClient for #{uid}" }
      end
      user.save_last_toot_id
    end
  end

  private

  def mastodon_domain
    uid.split('@').last
  end
end
