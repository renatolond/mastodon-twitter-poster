source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# The web framework
gem "rails", "~> 5.2.3"
gem "rails-i18n"
gem "pg"
gem "puma"
gem "sass-rails"
gem "uglifier"
# Improve app boot time
gem "bootsnap", ">= 1.1.0", require: false

gem "coffee-rails"
gem "turbolinks"
gem "jbuilder"

gem "mastodon-api", require: "mastodon", github: "tootsuite/mastodon-api", branch: "master"
gem "twitter", github: "renatolond/twitter", branch: "different_uploads"
gem "devise"
gem "devise-i18n" # translations for devise forms
gem "omniauth-twitter"
gem "omniauth-mastodon", github: "renatolond/omniauth-mastodon"
gem "omniauth-rails_csrf_protection" # mitigate CVE-2015-9284
gem "nokogiri"
gem "htmlentities"
gem "webpacker"
# Used to get medias from Twitter and Mastodon
gem "httparty"

gem "statsd-ruby"
gem "foreman"
gem "dotenv-rails"
gem "ruby-filemagic"

# Used for background jobs
gem "sidekiq"
# Used to be able to schedule background jobs
gem "sidekiq-scheduler"
# Used to be able to avoid doubled sidekiq jobs
gem "sidekiq-unique-jobs"

# Used to validate text length before submitting to twitter
gem "twitter-text"

group :development, :test do
  gem "byebug"
  gem "pry"
  gem "pry-byebug"
  gem "capybara"
  gem "selenium-webdriver"
  gem "timecop"
end

group :test do
  gem "factory_bot_rails"
  gem "faker"
  gem "mocha"
  gem "simplecov", require: false
  gem "webmock"
end

group :development do
  gem "web-console"
  gem "listen"
  gem "spring"
  gem "spring-watcher-listen"
end

group :production do
  gem "rails_12factor"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data"

gem "http_accept_language"
