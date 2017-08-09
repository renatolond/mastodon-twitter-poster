require 'pry'
module Mastodon
  class Status
    def is_reblog?
      begin
        _ = reblog
        true
      rescue NoMethodError
        false
      end
    end
  end
end
class CheckForToots
  OLDER_THAN_IN_SECONDS = 30
  def self.available_since_last_check
    u = User.where('mastodon_last_check < now() - interval \'? seconds\'', OLDER_THAN_IN_SECONDS).order(mastodon_last_check: :asc).first
    return unless u.mastodon
    opts = {}
    opts[:since_id] = u_last_toot unless u.last_toot.nil?
    new_toots = u.mastodon_client.statuses(u.mastodon_id, opts)
    binding.pry
  end
end
