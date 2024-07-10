require 'sidekiq/web'

# Configure Sidekiq-specific session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_interslice_session"

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  mount Sidekiq::Web => '/sidekiq'

  get "up" => "rails/health#show", as: :rails_health_check

  post "sign_in", to: "auth#sign_in"
  post "sign_up", to: "auth#sign_up"

  resources :places
  resources :photos
end
