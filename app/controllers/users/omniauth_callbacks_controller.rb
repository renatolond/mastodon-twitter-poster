class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:failure]

  def all
    user = User.from_omniauth(request.env["omniauth.auth"], current_user)

    if user && user.persisted?
      sign_in_and_redirect(user)
    else
      redirect_to root_path, flash: { error: "Sorry, login failed." }
    end
  end

  def after_sign_in_path_for(resource)
    if resource.mastodon && resource.twitter &&
        !(resource.posting_from_twitter? || resource.posting_from_mastodon?)
      user_path
    else
      super
    end
  end

  alias twitter  all
  alias mastodon all

  def failure
    redirect_to root_path, flash: { error: failure_message }
  end
end
