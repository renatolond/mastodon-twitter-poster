# Mastodon-Twitter Crossposter [![Maintainability](https://api.codeclimate.com/v1/badges/5ce2dc7dbf21d7a7fd4d/maintainability)](https://codeclimate.com/github/renatolond/mastodon-twitter-poster/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/5ce2dc7dbf21d7a7fd4d/test_coverage)](https://codeclimate.com/github/renatolond/mastodon-twitter-poster/test_coverage) [![Build Status](https://travis-ci.org/renatolond/mastodon-twitter-poster.svg?branch=master)](https://travis-ci.org/renatolond/mastodon-twitter-poster)

This is an app for crossposting between Mastodon and Twitter. The app is made so that multiple users can connect to it using the OAuth interface from both Twitter and Mastodon and choose options on how the crosspost should work.

If you just want to use it, there's one running at https://crossposter.masto.donte.com.br, which you can use from whatever Mastodo server you are in 🙂

## Features

* Post from Twitter to Mastodon
  - You can choose between posting only your tweets, or also posting retweets and quotes. 
  - You can choose between posting retweets and quotes as links or as the old-style RTs, starting by RT @username@twitter.com.
  - Quotes bigger than 500 characters are automatically split in two toots, one replying to the other.
  - Your own threads can also be crossposted!
  - No other replies will be posted. There's no risk of filling your Mastodon timeline with replies to people that are not there 

* Post from Mastodon to Twitter
  - Mind your privacy: you can choose which privacy levels you want to crosspost. Only posting public toots, for instance.
  - You can choose between posting boosts or not.
  - Automatically fix mentions to twitter users! If you post @user@twitter.com they will be mentioned on twitter when the toot gets crossposted.
  - Your own threads can also be crossposted, obeying to the choices you made regarding your privacy.
  - Any toot bigger than 280 characters will be posted with a link to the original toot. (Be careful, if you post your private toots, your followers might not be able to see the original post!)
  
The crossposter will never follow anyone or post anything but the content you selected to be crossposted.

If you decide to crosspost from Twitter to Mastodon, remember to turn on notifications about when people mention you to avoid not seeing interactions!

## Ruby on Rails

Ruby 2.4.2

Rails 5.1

## Requirements

Without extra configuration, a local postgres instance is needed. Node 6.11 is needed for statsd, can be installed using [nvm](https://github.com/creationix/nvm).

## Setup

You need to install Yarn and Ruby 2.4.2. Yarn has installation instructions for several OSs here: https://yarnpkg.com/lang/en/docs/install/ and Ruby can be installed either using RVM (https://rvm.io/rvm/install) or rbenv (https://github.com/rbenv/rbenv#installation). After you have ruby and yarn setup, you'll need to do:

```
# Install bundler
gem install bundler
# Use bundler to install Ruby dependencies
bundle install --deployment --without development test
# Use yarn to install node.js dependencies
yarn install --pure-lockfile
```

A separate user is recommended.

By default, the crossposter will use a statsd instance to send error and stats data to Librato. If you don't want that or want to setup something else, you need to change `statsd-config.js`

To start the web app, the worker which will fetch tweets and toots in background and the statsd instance, you need to do:
`bundle exec foreman start -e .env.production"`

If you are using systemd, you can create a service with something like:

```
[Unit]
Description=crossposter-service
After=network.target

[Service]
Type=simple
User=crossposter
WorkingDirectory=/home/crossposter/live
ExecStart=/bin/bash -lc "bundle exec foreman start -e .env.production"
TimeoutSec=15
Restart=always

[Install]
WantedBy=multi-user.target
```
And put it on `/etc/systemd/system/crossposter.service`

## Tests

Run `RAILS_ENV=test bundle exec rake db:setup` to create the test database (a postgres running locally is needed), and after that run the tests with `bundle exec rake test` (or `COVERAGE=1 bundle exec rake test` if coverage information is desired)

## Starting
To start the project locally, you can do `foreman start` which will start both the webserver and the daemons. Or you can take a look at the procfile to start each of them separately (if you don't want the web interface to be accessible, for instance).
