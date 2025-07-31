class StaticController < ApplicationController
  # GET /
  # Trang chủ tĩnh không cần cơ sở dữ liệu
  def index
    # Không cần truy vấn cơ sở dữ liệu
    render 'index'
  end
end
