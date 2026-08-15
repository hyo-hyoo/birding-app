Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.local?
    get "previews/login", to: "frontend_previews#login", as: :frontend_preview_login
    get "previews/register", to: "frontend_previews#register", as: :frontend_preview_register
    get "previews/verification-sent", to: "frontend_previews#verification_sent", as: :frontend_preview_verification_sent
    get "previews/verification-success", to: "frontend_previews#verification_success", as: :frontend_preview_verification_success
    get "previews/reset-request", to: "frontend_previews#reset_request", as: :frontend_preview_reset_request
    get "previews/reset-password", to: "frontend_previews#reset_password", as: :frontend_preview_reset_password
    get "previews/reset-success", to: "frontend_previews#reset_success", as: :frontend_preview_reset_success
    get "previews/history-empty", to: "frontend_previews#history_empty", as: :frontend_preview_history_empty
    get "previews/history", to: "frontend_previews#history", as: :frontend_preview_history
    get "previews/outline", to: "frontend_previews#outline", as: :frontend_preview_outline
    get "previews/editor", to: "frontend_previews#editor", as: :frontend_preview_editor
    get "previews/detail", to: "frontend_previews#detail", as: :frontend_preview_detail
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
