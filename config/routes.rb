Rails.application.routes.draw do
  # Sử dụng StaticController thay vì HomeController để không cần cơ sở dữ liệu
  root "static#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
