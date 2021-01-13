class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  around_action :set_locale

  def set_locale(&action)
    locale = params[:locale] || http_accept_language.compatible_language_from(I18n.available_locales) || I18n.default_locale
    I18n.with_locale(locale, &action)
  end
end
