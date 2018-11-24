source "https://rubygems.org"

ruby "2.5.3"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "rails", "~> 5.1.6"
gem "rails-i18n"
gem "pg"
gem "puma"
gem "sass-rails"
gem "uglifier"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

gem "coffee-rails"
gem "turbolinks"
gem "jbuilder"

gem "mastodon-api", require: "mastodon", github: "renatolond/mastodon-api", branch: "accept_headers_and_update_image_description"
gem "twitter", github: "renatolond/twitter", branch: "different_uploads"
gem "devise"
gem "devise-i18n" # translations for devise forms
gem "omniauth-twitter"
gem "omniauth-mastodon"
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
