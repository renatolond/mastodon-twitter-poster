require "sidekiq/web"
require "sidekiq_unique_jobs/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  resource :account
  resources :authorizations, only: [:destroy]

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  devise_scope :user do
    delete "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end

  resource :user do
    get "advanced_mastodon"
    get "advanced_twitter"
    get "mastodon_identifier"
  end
  root to: "home#index"

  unless Rails.configuration.x.privacy_url then
    get "privacy", to: "home#privacy"
  else
    get "privacy", to: redirect(Rails.configuration.x.privacy_url, status: 302)
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
