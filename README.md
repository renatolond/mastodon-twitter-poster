# Mastodon-Twitter Crossposter [![Code Climate](https://codeclimate.com/github/renatolond/mastodon-twitter-poster/badges/gpa.svg)](https://codeclimate.com/github/renatolond/mastodon-twitter-poster) [![Test Coverage](https://codeclimate.com/github/renatolond/mastodon-twitter-poster/badges/coverage.svg)](https://codeclimate.com/github/renatolond/mastodon-twitter-poster/coverage) [![Build Status](https://travis-ci.org/renatolond/mastodon-twitter-poster.svg?branch=master)](https://travis-ci.org/renatolond/mastodon-twitter-poster)

This is an app for crossposting between Mastodon and Twitter. The app is made so that multiple users can connect to it using the OAuth interface from both Twitter and Mastodon and choose options on how the crosspost should work (TBD).

## Ruby on Rails

Ruby 2.4.1

Rails 5.1

## Tests

We're currently lacking on tests :P

## Starting
To start the project locally, you can do `foreman start` which will start both the webserver and the daemons. Or you can take a look at the procfile to start each of them separately (if you don't want the web interface to be accessible, for instance).
