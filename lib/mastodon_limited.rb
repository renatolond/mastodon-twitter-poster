require "mastodon"

module OmniAuth
  module Strategies
    class MastodonLimited < OmniAuth::Strategies::Mastodon
      def start_oauth
        username, domain = identifier.split("@")

        if blocked_domains.present? && blocked_domains.include?(domain)
          fail!(:forbidden_domain, CallbackError.new("forbidden_domain", I18n.t("errors.oauth.blocked_domain", domain: domain)))
        elsif allowed_domains.present? && !allowed_domains.include?(domain)
          fail!(:forbidden_domain, CallbackError.new("forbidden_domain", I18n.t("errors.oauth.allowed_domains", domains: allowed_domains.join(", "))))
        else
          super
        end
      end

      def blocked_domains
        @blocked_domains ||= ENV["BLOCKED_DOMAINS"]&.split(/\s*,\s*/)
      end

      # accept ALLOWED_DOMAIN for legacy reasons
      def allowed_domains
        @allowed_domains ||= (ENV["ALLOWED_DOMAIN"] || ENV["ALLOWED_DOMAINS"])&.split(/\s*,\s*/)
      end
    end
  end
end
