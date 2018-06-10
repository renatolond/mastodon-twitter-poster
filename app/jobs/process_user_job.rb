require 'mastodon_ext'
require 'mastodon_user_processor'
require 'twitter_user_processor'
require 'stats'

class ProcessUserJob < ApplicationJob
  queue_as :default

  def self.stats
    @@stats ||= Stats.new
  end

  def perform(id)
    u = User.find(id)
    self.class.stats.time('twitter.processing_time') { TwitterUserProcessor::process_user(u) } if u.posting_from_twitter
    self.class.stats.time('mastodon.processing_time') { MastodonUserProcessor::process_user(u) } if u.posting_from_mastodon
    u.locked = false
    u.save
  end
end
