FactoryGirl.define do
  factory :authorization, aliases: [:authorization_mastodon] do
    provider :mastodon
    uid Faker::Internet.email
    user
    token 'a-beautiful-token-here'
  end

  factory :authorization_twitter, parent: :authorization do
    provider :twitter
    uid 123456
    user
    token 'another-beautiful-token-here'
    secret 'another-beautiful-secret-here'
  end
end
