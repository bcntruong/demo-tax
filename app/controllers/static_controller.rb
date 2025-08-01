class StaticController < ApplicationController
  # GET /
  # Trang chủ tĩnh không cần cơ sở dữ liệu
  def index
    # Không cần truy vấn cơ sở dữ liệu
    @tax_features = [
      "Tính thuế thu nhập cá nhân",
      "Tính thuế giá trị gia tăng",
      "Tính thuế thu nhập doanh nghiệp",
      "Báo cáo thuế hàng tháng",
      "Xuất báo cáo PDF"
    ]
    
    @contact_info = {
      email: "contact@demo-tax.com",
      phone: "0123-456-789",
      address: "123 Đường ABC, Quận XYZ, TP. Hồ Chí Minh"
    }
    
    render 'index'
  end
end
