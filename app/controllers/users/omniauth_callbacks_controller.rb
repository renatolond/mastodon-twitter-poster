class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def all
    user = User.from_omniauth(request.env['omniauth.auth'], current_user)

    if user && user.persisted?
      sign_in_and_redirect(user)
    else
      redirect_to root_path, flash: {error: "Sorry, login failed."}
    end
  end

  alias twitter  all
  alias mastodon all

  def failure
    redirect_to root_path
  end
end
