FactoryBot.define do
  factory :user do
    transient do
      username { Faker::Internet.user_name }
    end
    last_toot { 1 }
    last_tweet { 1000000 }
    twitter_last_check { Time.now }
    mastodon_last_check { Time.now }
    posting_from_mastodon { false }
    posting_from_twitter { false }
    masto_fix_cross_mention { false }
    masto_should_post_unlisted { false }
    masto_should_post_private { false }
    boost_options { 'masto_boost_do_not_post' }
    masto_reply_options { 'masto_reply_do_not_post' }
    masto_mention_options { 'masto_mention_do_not_post' }
    retweet_options { 'retweet_do_not_post' }
    twitter_reply_options { 'twitter_reply_do_not_post' }
    twitter_original_visibility { nil }
    twitter_retweet_visibility { 'unlisted' }
    twitter_quote_visibility { 'unlisted' }
  end

  factory :user_with_mastodon_and_twitter, parent: :user do |user|
    transient do
      masto_domain { Faker::Internet.domain_name }
    end
    after(:build) do |user, evaluator|
      user.authorizations << build(:authorization_mastodon, user: user, masto_domain: evaluator.masto_domain, uid: "#{evaluator.username}@#{evaluator.masto_domain}")
      user.authorizations << build(:authorization_twitter, user: user)
    end

    after(:create) do |user|
      user.authorizations.each { |authorization| authorization.save! }
    end
  end
end
