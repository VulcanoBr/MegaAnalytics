Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"
  get "dashboard", to: "dashboard#show", as: :dashboard
  get "frequency", to: "frequencies#show", as: :frequency
  get "combinations", to: "combinations#show", as: :combinations
  get "distributions", to: "distributions#show", as: :distributions

  resources :draws, only: %i[index show]
  resource :report, only: :show

  resources :import_batches, only: %i[index new create show]
end
