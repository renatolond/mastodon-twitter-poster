source 'https://rubygems.org'

ruby '2.4.2'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.2'
gem 'rails-i18n', '~> 5.0.0'
gem 'pg', '~> 0.18'
gem 'puma', '~> 3.7'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

gem 'coffee-rails', '~> 4.2'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'mastodon-api', require: 'mastodon', :github => 'renatolond/mastodon-api', branch: 'accept_headers_and_update_image_description'
gem 'twitter', :github => 'renatolond/twitter', branch: 'different_uploads'
gem 'devise'
gem 'omniauth-twitter'
gem 'omniauth-mastodon'
gem 'nokogiri'
gem 'htmlentities'
gem 'daemons'
gem 'webpacker'
gem 'httparty'

gem 'statsd-ruby'
gem 'foreman'
gem 'dotenv-rails'
gem 'ruby-filemagic'
gem 'sidekiq'

group :development, :test do
  gem 'byebug'
  gem 'pry'
  gem 'pry-byebug'
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
  gem 'timecop'
end

group :test do
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'mocha'
  gem 'simplecov', :require => false
  gem 'webmock'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :production do
  gem 'rails_12factor'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data'

gem "http_accept_language", "~> 2.1"
