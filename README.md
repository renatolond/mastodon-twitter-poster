# Mastodon-Twitter Crossposter [![Code Climate](https://codeclimate.com/github/renatolond/mastodon-twitter-poster/badges/gpa.svg)](https://codeclimate.com/github/renatolond/mastodon-twitter-poster) [![Test Coverage](https://codeclimate.com/github/renatolond/mastodon-twitter-poster/badges/coverage.svg)](https://codeclimate.com/github/renatolond/mastodon-twitter-poster/coverage) [![Build Status](https://travis-ci.org/renatolond/mastodon-twitter-poster.svg?branch=master)](https://travis-ci.org/renatolond/mastodon-twitter-poster)

This is an app for crossposting between Mastodon and Twitter. The app is made so that multiple users can connect to it using the OAuth interface from both Twitter and Mastodon and choose options on how the crosspost should work.

## Ruby on Rails

Ruby 2.4.1

Rails 5.1

## Requirements

Without extra configuration, a local postgres instance is needed. Node 6.11 is needed for statsd, can be installed using [nvm](https://github.com/creationix/nvm).

## Tests

Run `RAILS_ENV=test bundle exec rake db:setup` to create the test database (a postgres running locally is needed), and after that run the tests with `bundle exec rake test` (or `COVERAGE=1 bundle exec rake test` if coverage information is desired)

## Starting
To start the project locally, you can do `foreman start` which will start both the webserver and the daemons. Or you can take a look at the procfile to start each of them separately (if you don't want the web interface to be accessible, for instance).

## TODO
- Add tests for Mastodon User Processor
- Add option to disable posting toot or tweet with a mention on the body (request)
- Cache known tweets and toots for some time to enable smart replies and both networks on at the same time
