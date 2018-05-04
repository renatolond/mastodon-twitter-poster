module ApplicationHelper
  def twitter?
    user_signed_in? && !current_user.twitter.nil?
  end

  def mastodon?
    user_signed_in? && !current_user.mastodon.nil?
  end

  def translated_masto_privacy_for_select(class_name, enum)
    class_name.send(enum.to_s.pluralize).map do |key, _|
      [I18n.t("masto_privacy.#{key}"), key]
    end
  end
end
