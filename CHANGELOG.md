[2018-11-23] - Removed daemons. Recommended services changed, take a look on new recommendation.

*Action is needed!* You need to run from a rails console session (can be accessed by using `RAILS_ENV=production bundle exec rails console` from your server):

```
Sidekiq::DeadSet.new.each do |job|
  job.retry
end

Sidekiq::RetrySet.new.each do |job|
  job.retry;
end
```

[2018-11-14] - Remove statsd, create env variables to use to statsd if wanted, service examples updated
