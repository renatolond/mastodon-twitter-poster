source "https://rubygems.org"

# The framework
gem "rails", "~> 7.0.1"
gem "rails-i18n"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 5.0"

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
# gem "sassc-rails"

# Responsible for user auth
gem "devise"
gem "devise-i18n" # translations for devise forms
gem "omniauth-twitter"
gem "omniauth-mastodon", github: "renatolond/omniauth-mastodon"
gem "omniauth-rails_csrf_protection" # mitigate CVE-2015-9284

# Used for accessing the APIs, translating responses, etc
gem "mastodon-api", require: "mastodon", github: "tootsuite/mastodon-api", branch: "master"
gem "twitter", github: "renatolond/twitter", branch: "different_uploads"
gem "nokogiri"
gem "htmlentities"

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
gem "sidekiq-unique-jobs", "~> 6.0"

# Used to validate text length before submitting to twitter
gem "twitter-text"

# Used for locale guessing
gem "http_accept_language"

gem "rake"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]

  # Code formatting facilities
  gem "lefthook", require: false
  gem "pronto", require: false, github: "prontolabs/pronto", ref: "a84f946f155c5a95946d4a52131ca037789cda9e" # While a new release is not cut containing the default_commit functionality
  gem "pronto-rubocop", require: false
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false

  gem "capybara"
  gem "selenium-webdriver"
  gem "timecop"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  gem "factory_bot_rails"
  gem "faker"
  gem "mocha"
  gem "simplecov", require: false
  gem "webmock"
end
