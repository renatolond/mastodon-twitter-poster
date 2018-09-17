FactoryBot.define do
  factory :status do
    mastodon_client
    tweet_id { Faker::Number.number(18) }
    masto_id { Faker::Number.number(18) }
  end
end
