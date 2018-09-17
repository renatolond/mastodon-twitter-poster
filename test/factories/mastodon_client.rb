FactoryBot.define do
  factory :mastodon_client do
    domain { Faker::Internet.domain_name }
    client_id { 'The-client-id' }
    client_secret { 'A-very-secret-key' }
  end
end
