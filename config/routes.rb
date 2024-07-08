Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  get "up" => "rails/health#show", as: :rails_health_check

  post "sign_in", to: "auth#sign_in"
  post "sign_up", to: "auth#sign_up"

  resources :places
end
