FactoryBot.define do
  factory :authorization, aliases: [:authorization_twitter] do
    provider { :twitter }
    uid { 123456 }
    user
    token { 'a-beautiful-token-here' }
    secret { 'another-beautiful-secret-here' }
  end

  factory :authorization_mastodon, parent: :authorization do
    transient do
      masto_domain { nil }
    end
    provider { :mastodon }
    uid { Faker::Internet.email }
    user
    token { 'another-beautiful-token-here' }
    secret { nil }
    mastodon_client { build(:mastodon_client, domain: masto_domain) unless masto_domain.nil? }

    after(:create) do |auth|
      auth.mastodon_client.save!
    end
  end
end
