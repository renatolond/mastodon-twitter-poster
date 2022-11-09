[2022-11-04] - Add Stoplight, a gem that acts as a circuit breaker. This will give a cooldown to servers that might be offline.

[2022-10-18] - Update gems and node dependencies. `bundle install` and `yarn install --pure-lockfile` needed after upgrade.
Node version upgraded due do a dependency, higher than 14 needed.

[2022-02-22] - Update gems and node dependencies. `bundle install` and `yarn install --pure-lockfile` needed after upgrade. Attempts at speeding up job creation to deal with occasional doubled posts.

[2022-06-05] - Fix char count for twitter alt text. Make placeholder more consistent (#735). Update gems and node dependencies. `bundle install` and `yarn install --pure-lockfile` needed after upgrade.

[2022-05-18] - Update gems and node dependencies. `bundle install` and `yarn install --pure-lockfile` needed after upgrade. Remove twitter.activitypub.actor as per [#725](https://github.com/renatolond/mastodon-twitter-poster/issues/725)

[2022-05-01] - Update gems and node dependencies. `bundle install` and `yarn install --pure-lockfile` needed after upgrade. Note that one of the dependencies now needs Redis >= 4.2.0.

[2022-02-22] - Update gems and node dependencies. `bundle install` and `yarn install --pure-lockfile` needed after upgrade.

[2022-02-04] - Update needed node version, higher than 12 is needed. Update gems and node dependencies. `bundle install` and `yarn install --pure-lockfile` needed after upgrade.

[2022-01-17] - Major framework upgrade.
Node version upgraded, higher than 10.16 needed.
Ruby version upgraded to 3.1.0. The crossposter should still work in previous versions, though new features of ruby >3.0 will be used in the future, for the moment you can change the version on `.ruby-version`.
`bundle install` and `yarn install --pure-lockfile` needed after upgrade. Then `rails assets:precompile`.

[2021-01-27] - Upgrade gems. `bundle install` needed after upgrade.

[2021-01-13] - Added new option to control CW when crossposting from Mastodon. `rails db:migrate` needed after upgrade.

[2020-11-20] - Upgrade gems. `bundle install` needed after upgrade.

[2020-03-28] - Add mastodon user id to the authorizations model to reduce API calls. `rails db:migrate` needed after upgrade.

[2020-03-17] - Update needed node version, higher than 8.16 is needed. Update gems and node dependencies. `bundle install` and `yarn install --pure-lockfile` needed after upgrade.

[2020-03-02] - Upgrade gems. `bundle install` needed after upgrade.

[2020-01-16] - Upgrade gems. `bundle install` needed after upgrade. Fixed a bug with boosts. Fixed a bug with long quote retweets.

[2020-01-16] - Upgrade gems. `bundle install` needed after upgrade. Increased read timeout to 20s.

[2020-01-13] - Update gems and node dependencies. `bundle install` and `yarn install --pure-lockfile` needed after upgrade.

[2020-01-04] - Upgrade gems. `bundle install` needed after upgrade.

[2019-12-26] - Upgrade gems. `bundle install` needed after upgrade.

[2019-12-09] - Updated Czech translation (#272). Update gems and node dependencies. `bundle install` needed after upgrade.

[2019-11-11] - Fixed small bugs. Update gems and node dependencies. `bundle install` and `yarn install --pure-lockfile` needed after upgrade.

[2019-11-03] - Update ruby to 2.6.5. The crossposter still works on 2.5.x or 2.6.x, so if you don't want to upgrade, you can change the version on `.ruby-version`. Also upgrade gems. `bundle install` needed after upgrade.

[2019-08-09] - Upgrade gems. `bundle install` needed after upgrade.

[2019-08-01] - Upgrade gems. `bundle install` needed after upgrade.

[2019-07-28] - Upgrade gems. `bundle install` needed after upgrade.

[2019-07-14] - Blocking domains also blocks subdomains. Gab and kiwifarms are now always blocked.

[2019-05-31] - Upgrade ruby to 2.6.3. Also upgrade some gems. `bundle install` needed after upgrade.

[2019-03-14] - Upgrade rails. `bundle install` needed after upgrade.

[2019-03-14] - Update ruby to 2.6.1. The crossposter still works on 2.5.x, so if you don't want to upgrade, you can change the version on `.ruby-version`.

[2019-03-14] - Update rails. `bundle install` needed after upgrade.

[2019-02-26] - Fix an overseen issue with pleroma status id which is a string. `rails db:migrate` needed after upgrade.

[2019-02-21] - Add option to use twitter.activitypub.actor or similar to mention twitter people

[2019-02-02] - Add admin status to users table. Instructions on how to make a user an admin are available in the README file. `rails db:migrate` needed after upgrade.

[2019-01-31] - Fix issue with pleroma status id which is a string. `rails db:migrate` needed after upgrade.

[2019-01-09] - Update gems and node dependencies. `bundle install` and `yarn install --pure-lockfile` needed after upgrade.

[2018-12-11] - Added BLOCKED_DOMAINS variable, more information on README.

[2018-12-01] - Added bulma-rtl, `yarn install --pure-lockfile` and `rails assets:precompile` needed after upgrade.

[2018-11-23] - Removed daemons. Recommended services changed, take a look on new recommendation.

*Action is needed!* For this release, you need to upgrade the code, install the needed dependencies, restart the service and then run the following from a rails console session (can be accessed by using `RAILS_ENV=production bundle exec rails console` from your server) :

```
Sidekiq::DeadSet.new.each do |job|
  job.retry
end

Sidekiq::RetrySet.new.each do |job|
  job.retry;
end
```

This will cause the current jobs to be switched to the new worker mode.

[2018-11-14] - Remove statsd, create env variables to use to statsd if wanted, service examples updated
