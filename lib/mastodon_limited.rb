require "mastodon"

module OmniAuth
  module Strategies
    class MastodonLimited < OmniAuth::Strategies::Mastodon
      def start_oauth
        username, domain = identifier.split("@")

        if blocked_domains.present? && blocked_domains.include?(domain)
          fail!(:forbidden_domain, CallbackError.new("forbidden_domain", "Sorry, #{domain} is blocked in this instance."))
        elsif allowed_domain.present? && allowed_domain != domain
          fail!(:forbidden_domain, CallbackError.new("forbidden_domain", "Sorry, only %s Mastodon Accounts are allowed." % allowed_domain))
        else
          super
        end
      end

      def blocked_domains
        @blocked_domains ||= ENV["BLOCKED_DOMAINS"]&.split(/\s*,\s*/)
      end

      def allowed_domain
        ENV["ALLOWED_DOMAIN"]
      end
    end
  end
end
