<p align="center"><img src="app/logo/Logo1.png" alt="mastodon-twitter-poster" height="300px"></p>


# Mastodon-Twitter Crossposter [![Maintainability](https://api.codeclimate.com/v1/badges/5ce2dc7dbf21d7a7fd4d/maintainability)](https://codeclimate.com/github/renatolond/mastodon-twitter-poster/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/5ce2dc7dbf21d7a7fd4d/test_coverage)](https://codeclimate.com/github/renatolond/mastodon-twitter-poster/test_coverage)  [![Translation status](https://hosted.weblate.org/widgets/mastodon-twitter-crossposter/-/svg-badge.svg)](https://hosted.weblate.org/engage/mastodon-twitter-crossposter/)

This is an app for crossposting between Mastodon and Twitter. The app is made so that multiple users can connect to it using the OAuth interface from both Twitter and Mastodon and choose options on how the crosspost should work.

If you just want to use it, there's one running at https://crossposter.masto.donte.com.br, which you can use from most Mastodon servers (except the ones [suspended at masto.donte.com.br](https://github.com/masto-donte-com-br/InstanceInternals/blob/master/Blocklist.md)).

## Features

* Post from Twitter to Mastodon
  - You can choose between posting only your tweets, or also posting retweets and quotes.
  - You can choose between posting retweets and quotes as links or as the old-style RTs, starting by RT @username@twitter.com.
  - Quotes bigger than 500 characters are automatically split in two toots, one replying to the other.
  - Your own threads can also be crossposted!
  - No other replies will be posted. There's no risk of filling your Mastodon timeline with replies to people that are not there.
  - Images and videos are crossposted to Mastodon. The best quality that fits in Mastodon will be crossposted!
  - Image and any other media descriptions from Twitter are completely crossposted to Mastodon
  - Possibility to add a content warning to all tweets being posted to Mastodon
  - Infer content warnings: if your tweet begins with a line containing "content warning" it will be posted behind a content warning on Mastodon. More information about which formats are supported can be seen below at [Experimental Content Warning recognition](#experimental-content-warning-recognition)
  - Blocklists or Allowlists: Only crosspost tweets containing one word from a list or do not crosspost tweets that contain at least one word from a list

* Post from Mastodon to Twitter
  - Any toot bigger than 280 characters will be posted with a link to the original toot. (Be careful, if you post your private toots, your followers might not be able to see the original post!)
  - Mind your privacy: you can choose which privacy levels you want to crosspost. Only posting public toots, for instance.
  - Images and videos will be crossposted over to Twitter
  - Images and video descriptions from Mastodon will be crossposted to Twitter, in medias where Twitter support descriptions
  - Choose how to handle toots with content warnings; crosspost only the CW, only the content, or both! If only the CW is crossposted, the tweet will also include a link to the original toot, so your followers can read the content on Mastodon if they want.
  - If your image is marked as sensitive, the rest of the toot will be crossposted, together with a hint that there's images attached and a link to the original post.
  - You can choose between posting boosts or not.
  - Your own threads can also be crossposted, respecting to the choices you made regarding your privacy.
  - No other replies will be posted. There's no risk of filling your twitter timeline with replies to people that are not there.
  - Blocklists or Allowlists: Only crosspost toots containing one word from a list or do not crosspost tweets that contain at least one word from a list

The crossposter will never follow anyone or post anything but the content you selected to be crossposted.

If you decide to crosspost from Twitter to Mastodon, remember to turn on notifications about when people mention you to avoid not seeing interactions!

## Note on usage

The crossposter is made with multiple users in mind. For that reason, it can be quite a lot of moving parts if you want to self-host yourself. There's other good tools to self-host out there like https://github.com/AmauryCarrade/MastodonToTwitter and the others listed at the [Bridges from/to other platforms section of the Mastodon apps](https://github.com/felx/mastodon-documentation/blob/master/Using-Mastodon/Apps.md#bridges-fromto-other-platforms). That being said, it should work even if you only want it for your own usage.

## Ruby on Rails

Ruby 3.1.0

Rails 7.0

## Requirements

Without extra configuration, a local postgres instance is needed. Node is needed for assets compilation, can be installed using [nvm](https://github.com/creationix/nvm).

The poster uses the [ruby-filemagic gem](https://github.com/blackwinter/ruby-filemagic) for detecting the types of the files posted. Follow the instructions described in the README to install the needed library and headers.

## Pre-setup

* Mastodon tokens are generated by the application, but for twitter you need to request an API Token from their side.
* You need a consumer key (on our side `TWITTER_CLIENT_ID`) and consumer secret (on our side `TWITTER_CLIENT_SECRET`).
* Twitter app callback URL should be set to `https://crossposter.example.com/users/auth/twitter/callback`.

## Setup

Note: If you are running side-by-side with Mastodon or other sidekiq-using software, you need to configure redis to avoid issues with mixed jobs. More info at the end.

You need to install Yarn and Ruby 3.1.0. Yarn has installation instructions for several OSs here: https://yarnpkg.com/lang/en/docs/install/ and Ruby can be installed either using RVM (https://rvm.io/rvm/install) or rbenv (https://github.com/rbenv/rbenv#installation). After you have ruby and yarn setup, you'll need to do:

```
# Install bundler
gem install bundler
# Use bundler to install Ruby dependencies
bundle install --deployment --without development test
# Use yarn to install node.js dependencies
yarn install --pure-lockfile
```

A separate user is recommended.

If you want the crossposter to send data to a statsd instance, you need to configure the appropriate variables in the .env file. You can check the example for reference.

Before starting for the first time, you need to generate the assets and setup the database:

```
bundle exec rake db:setup # sets up the database
bundle exec rake assets:precompile # generates the assets
```

An example nginx configuration can be found at `util/nginx.conf`. It assumes the crossposter is running at port 3000, in the directory `/home/crossposter/live` and the domain `crossposter.example.com` needs to be replaced by your own.

An example of the configuration file is provided at `.env.example`. To generate `SECRET_KEY_BASE`, you need to run `bundle exec rake secret` and copy the resulting hash. You need to configure an app on Twitter with permission to read and write. The credentials that they give you need to be added to TWITTER_CLIENT_ID and TWITTER_CLIENT_SECRET. \\
If you're not using Librato, you don't need to fill any of the Librato variables.

To start the web app, you need to do:
`bundle exec puma -C config/puma.rb"`

If you are using systemd, you can create a service with something like:

```
[Unit]
Description=mastodon-twitter-crossposter
After=network.target

[Service]
Type=simple
User=crossposter
WorkingDirectory=/home/crossposter/live
Environment="RAILS_ENV=production"
Environment="RAILS_LOG_TO_STDOUT=enabled"
Environment="PORT=3001"
ExecStart=/bin/bash -lc "bundle exec puma -C config/puma.rb"
TimeoutSec=15
Restart=always

[Install]
WantedBy=multi-user.target
```
And put it on `/etc/systemd/system/crossposter.service`

And a second one like this:

```
[Unit]
Description=mastodon-twitter-crossposter-sidekiq
After=network.target

[Service]
Type=simple
User=crossposter
WorkingDirectory=/home/crossposter/live
Environment="RAILS_ENV=production"
Environment="RAILS_LOG_TO_STDOUT=enabled"
Environment="RAILS_MAX_THREADS=5"
ExecStart=/bin/bash -lc "bundle exec sidekiq -c 5 -q default"
TimeoutSec=15
Restart=always

[Install]
WantedBy=multi-user.target
```
And put it on `/etc/systemd/system/crossposter-sidekiq.service`
(note that RAILS_MAX_THREADS and the number of sidekiq threads should be the same)

These example files are provided in the `config/systemd-services` directory. You may copy these files (with necessary modifications, if applicable) to `/etc/systemd/system/` to run the system in the background.

### Running side-by-side with other sidekiq/redis applications

If you are running the crossposter on a server with other sidekiq/redis applications, you need extra configuration to make sure everything is separated.

For a more in-depth information, you can check out [Sidekiq Wiki](https://github.com/mperham/sidekiq/wiki/Using-Redis), but one thing you can do it's to use another redis db, which could be done by creating a file in `config/initializers/sidekiq.rb` with the content like

```
Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://redis.example.com:7372/2' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://redis.example.com:7372/2' }
end
```

You need to replace all values with actual values relevant to your server.

### Running in Docker

1. Create a `.env` based on `.env.example` and set `DB_HOST=db`, `DB_USER=postgres`, `REDIS_URL=redis://redis`
1. Start the app `docker-compose up -d --build`
1. Then init the db with `docker-compose run --rm web bundle exec rake db:setup`

## Blocked or allowed domains

You can add `ALLOWED_DOMAINS=your.domain.com` to .env.production to only allow users from your instance to access the crossposter. This variable can contain multiple instances separated by comma.

At the same time, you can add `BLOCKED_DOMAINS=evil.corp,bad.instance` to .env.production to block users from those instances to access the crossposter. They need to be separated by commas, spaces are optional.

You should only enable one at each time.

## Admin tasks

If you are an admin, you might want to make yourself an admin, which allows you to take a look on the status of the sidekiq queues (and solve possible issues that happen regarding users crossposting). To do so, you can run:

```
FEDIVERSE_USERNAME=your_user@your.domain.com RAILS_ENV=production bundle exec rake crossposter:make_admin
```

If you want a user to no longer be an admin of your crossposter, you can make so by running

```
FEDIVERSE_USERNAME=your_user@your.domain.com RAILS_ENV=production bundle exec rake crossposter:revoke_admin
```

## Tests

Run `RAILS_ENV=test bundle exec rake db:setup` to create the test database (a postgres running locally is needed), and after that run the tests with `bundle exec rake test` (or `COVERAGE=1 bundle exec rake test` if coverage information is desired)

## Starting
To start the project locally, you should use `bin/dev`, which will start all needed components. You need to have your local environment variables configured, common issues are that sidekiq can't find redis, which will make it fail to start. See the `Procfile.dev` for commands to run only some of the components.

For production, you need sidekiq to process jobs (that is, to post across the networks), but you only need the webserver if you want to change configurations or to allow new signups. If you're in a single user setup, you can start and stop the webserver as needed.

## Troubleshooting

If your server crashes and the crossposter is not correctly turned off, it might happen that jobs get into a state in which they are not able to recover by themselves. The symptom in this case is that no posts get crossposted and if you navigate to https://<your crossposter>/sidekiq, no jobs get ever added to the queue. If you get to that case, and there's a digest in the "unique digests" tab even without a corresponding job over at the "busy" tab, you can remove the unique digest and the job that inserts the status should start running again.

## Experimental Content Warning recognition
When posting from Twitter to Mastodon the Crossposter tries to detect content warnings in the tweets and post them over to Mastodon. The detected CW takes precedence over the default twitter one if exists. Some formats are supported and more can be added in the future, but currently, this are the ones that will be recognized:

```
CW: content warning
my tweet
```

```
TW: content warning
my tweet
```

```
CW/TW: content warning
my tweet
```

```
TW, CW, content warning
my tweet
```

```
Spoiler: content warning
my tweet
```

```
CN: content warning
my tweet
```

```
Contains: content warning
my tweet
```

```
Contém: content warning
my tweet
```

All of these posts will be posted in Mastodon with the same content: `my tweet` and will have a content warning of `content warning`. The crossposter attempts to remove any extra spaces between the `CW:` (or equivalent) tag.

This also works for quote-retweets. That is, if you are retweeting and you want to add a content warning to the tweet, you can just quote-retweet writing `CW: content warning`.
![Example of a quote-retweet adding a content warning](cw_quote_example.png)
![Example of the quote-retweet after being crossposted](crossposted_cw_quote_example.png)

This does not work for several tweets in a thread. Each tweet needs to have it's own CW.

Even though this is an experimental feature, it cannot be disabled. The reason is that content warnings are important for people in Mastodon and the crossposter should still try to keep it in a good environment, even if bringing content from Twitter.

## Contributing

Mastodon Twitter Crossposter is **100% free** and **open source**. We encourage and support an active, healthy community that accepts contributions from the public &ndash; including you!

There's a high level description of the crossposter over at [development help](https://github.com/renatolond/mastodon-twitter-poster/wiki/Development-help). You can start there and ask questions as needed!

## License

Copyright (C) 2017-2018 Renato Cerqueira & other crossposter contributors

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
