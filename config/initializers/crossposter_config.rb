# frozen_string_literal: true

Rails.application.configure do
  config.x.application_name = ENV.fetch('CROSSPOSTER_APP_NAME', 'Mastodon Twitter Crossposter')
  config.x.domain = ENV.fetch('CROSSPOSTER_DOMAIN')
  config.x.repo = ENV.fetch('CROSSPOSTER_REPO', 'https://github.com/renatolond/mastodon-twitter-poster')

  config.x.stats = ENV.fetch('CROSSPOSTER_STATS', nil)

  config.x.announcement_account_address = ENV.fetch('CROSSPOSTER_FEDI_ACCOUNT_ADDRESS')
  config.x.announcement_account_at = ENV.fetch('CROSSPOSTER_FEDI_ACCOUNT_AT')

  config.x.admin_twitter = ENV.fetch('CROSSPOSTER_ADMIN_TWITTER', nil)

  config.x.admin_fedi_address = ENV.fetch('CROSSPOSTER_ADMIN_FEDI_ADDRESS')
  config.x.admin_fedi_at = ENV.fetch('CROSSPOSTER_ADMIN_FEDI_AT')
end
