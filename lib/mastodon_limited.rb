require "mastodon"

module OmniAuth
  module Strategies
    class MastodonLimited < OmniAuth::Strategies::Mastodon
      def start_oauth
        username, domain = identifier.split("@")
        allowed_domain = ENV["ALLOWED_DOMAIN"]
        if (not allowed_domain) || (allowed_domain == domain)
          super
        else
          fail!(:forbidden_domain, CallbackError.new("forbidden_domain", "Sorry, only %s Mastodon Accounts are allowed." % allowed_domain))
        end
      end
    end
  end
end
