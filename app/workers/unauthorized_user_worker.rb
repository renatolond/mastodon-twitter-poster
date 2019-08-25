# frozen_string_literal: true

class UnauthorizedUserWorker
  include Sidekiq::Worker

  REVOKED_MESSAGES = ["O token de acesso foi revogado", "The access token was revoked", "Il token di accesso è stato disabilitato", "The access token is invalid", "アクセストークンは取り消されています", "Le jeton d’accès a été révoqué", "Der Zugriffs-Token wurde widerrufen", "access token 已被取消"].freeze
  INVALID_CREDENTIALS_MESSAGES = ["Invalid credentials."].freeze

  def perform(id)
    @user = User.find(id)
    check_twitter_credentials
    check_mastodon_credentials

    @user.locked = false
    @user.save
  rescue ActiveRecord::RecordNotFound
    Rails.logger.debug { "User not found, ignoring" }
  end

  private
    def check_twitter_credentials
      if @user.twitter
        begin
          @user.twitter_client.verify_credentials
        rescue Twitter::Error::Unauthorized => ex
          if ex.code == 89
            @user.twitter.destroy
            stop_crossposting
          else
            raise ex
          end
        end
      end
    end

    def check_mastodon_credentials
      if @user.mastodon
        begin
          @user.mastodon_client.verify_credentials
        rescue Mastodon::Error::Forbidden => ex
          # XXX same as below, there should be a code or machine-readable error field
          if INVALID_CREDENTIALS_MESSAGES.include? ex.message
            @user.mastodon.destroy
            stop_crossposting
          else
            # If it's a temporary error, we re-raise to avoid giving control back to posting worker
            raise ex
          end
        rescue Mastodon::Error::Unauthorized => ex
          # XXX look into this. There should be a code or machine-readable error field
          if REVOKED_MESSAGES.include? ex.message
            @user.mastodon.destroy
            stop_crossposting
          else
            # If it's a temporary error, we re-raise to avoid giving control back to posting worker
            raise ex
          end
        end
      end
    end

    def stop_crossposting
      @user.posting_from_twitter = @user.posting_from_mastodon = false
      @user.save
    end
end
