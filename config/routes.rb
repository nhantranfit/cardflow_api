Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      get "auth/me", to: "auth#me"
      resources :brands, only: %i[index create update destroy]
      resources :products, only: %i[index create update destroy]
      resources :clients, only: %i[index create update destroy] do
        resources :products, only: %i[create destroy], controller: "client_products", param: :product_id
      end
    end
  end
end
