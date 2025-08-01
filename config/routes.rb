Rails.application.routes.draw do
  # Sử dụng StaticController thay vì HomeController để không cần cơ sở dữ liệu
  root "static#index"
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Routes cho tính thuế thu nhập cá nhân
  get "tax-calculator", to: "tax_calculator#index", as: :tax_calculator
  post "tax-calculator/calculate", to: "tax_calculator#calculate", as: :calculate_tax
end
