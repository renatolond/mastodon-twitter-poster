require "mastodon"

module OmniAuth
  module Strategies
    class MastodonLimited < OmniAuth::Strategies::Mastodon
      def start_oauth
        username, domain = identifier.split("@")

        if blocked_domains.present?
          candidates = blocked_domains.select { |d| !!domain[d] }
          if candidates.include?(domain) || subdomain_match?(candidates, domain)
            fail!(:forbidden_domain, CallbackError.new("forbidden_domain", I18n.t("errors.oauth.blocked_domain", domain: domain)))
            return
          end
        end

        if allowed_domains.present? && !allowed_domains.include?(domain)
          fail!(:forbidden_domain, CallbackError.new("forbidden_domain", I18n.t("errors.oauth.allowed_domains", domains: allowed_domains.join(", "))))
          return
        end

        super
      end

      def blocked_domains
        @blocked_domains ||= (ENV["BLOCKED_DOMAINS"]&.split(/\s*,\s*/) | ["gab.com", "gab.ai", "kiwifarms.cc", "kiwifarms.is", "kiwifarms.net"])
      end

      # accept ALLOWED_DOMAIN for legacy reasons
      def allowed_domains
        @allowed_domains ||= (ENV["ALLOWED_DOMAIN"] || ENV["ALLOWED_DOMAINS"])&.split(/\s*,\s*/)
      end

      def subdomain_match?(candidates, domain)
        candidates.each do |candidate|
          return true if domain.match?(/.+\.#{candidates}/)
        end

        false
      end
    end
  end
end
