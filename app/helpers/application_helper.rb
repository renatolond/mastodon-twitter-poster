module ApplicationHelper
  def twitter?
    user_signed_in? && !current_user.twitter.nil?
  end

  def mastodon?
    user_signed_in? && !current_user.mastodon.nil?
  end
end
