# frozen_string_literal: true

class Cleanup
  def turn_off_crossposter_for_users_without_mastodon
    User.where('(select count(*) from authorizations where user_id=users.id and provider=\'mastodon\')=0').each do |u|
      next if u.mastodon

      u.update_columns(posting_from_twitter: false, posting_from_mastodon: false)
    end
  end

  def turn_off_crossposter_for_users_without_twitter
    User.where('(select count(*) from authorizations where user_id=users.id and provider=\'twitter\')=0').each do |u|
      next if u.twitter

      u.update_columns(posting_from_twitter: false, posting_from_mastodon: false)
    end
  end

  def remove_disabled_users_gone_for_longer_than_two_weeks
    User.where('updated_at < ?', 2.weeks.ago).where(posting_from_mastodon: false, posting_from_twitter: false).each do |u|
      u.authorizations.destroy_all
      u.destroy
    end
  end

  def clean_statuses_older_than_1_year
    Status.where('updated_at < ?', 1.year.ago).destroy_all
  end

  def clean_mastodon_clients_without_users
    MastodonClient.where('(select count(1) from authorizations where mastodon_clients.id = authorizations.mastodon_client_id) = 0').each do |mc|
      Status.where(mastodon_client: mc).destroy_all
      mc.destroy
    end
  end

  def call
    turn_off_crossposter_for_users_without_twitter
    turn_off_crossposter_for_users_without_mastodon
    remove_disabled_users_gone_for_longer_than_two_weeks
    clean_statuses_older_than_1_year
    clean_mastodon_clients_without_users
  end
end
