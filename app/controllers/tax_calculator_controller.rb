# frozen_string_literal: true

# Controller xử lý tính toán thuế thu nhập cá nhân
# @author Cascade
# @since 2025-08-01
class TaxCalculatorController < ApplicationController
  def index
    # Chuyển hướng về trang chủ
    redirect_to root_path
  end

  # Xử lý tính toán thuế thu nhập cá nhân
  # @return [void]
  def calculate
    @income = params[:income].present? ? params[:income].to_f : 0
    @dependents = params[:dependents].present? ? params[:dependents].to_i : 0
    @other_deductions = params[:other_deductions].present? ? params[:other_deductions].to_f : 0
    @insurance = params[:insurance].present? ? params[:insurance].to_f : 0

    # Validate dữ liệu đầu vào
    if validate_input
      # Sử dụng PersonalIncomeTaxService để tính thuế
      tax_service = PersonalIncomeTaxService.new(
        income: @income,
        dependents: @dependents,
        other_deductions: @other_deductions,
        insurance: @insurance
      )
      
      # Tính thuế và lấy kết quả
      @tax_result = tax_service.calculate
      @tax_details = tax_service.tax_details
      
      # Sử dụng flash để lưu dữ liệu cho request tiếp theo
      flash[:tax_result] = @tax_result
      flash[:tax_details] = @tax_details
      flash[:income] = @income
      flash[:dependents] = @dependents
      flash[:other_deductions] = @other_deductions
      flash[:insurance] = @insurance
      
      # Chuyển hướng về trang chủ với tham số hiển thị kết quả
      redirect_to root_path(show_tax_result: true)
    else
      # Lưu lỗi và chuyển hướng về trang chủ
      flash[:errors] = @errors
      redirect_to root_path
    end
  end

  private

  # Kiểm tra tính hợp lệ của dữ liệu đầu vào
  # @return [Boolean] true nếu dữ liệu hợp lệ, false nếu có lỗi
  def validate_input
    @errors = []
    
    # Validate thu nhập
    if params[:income].blank?
      @errors << "Vui lòng nhập tổng thu nhập."
    elsif @income <= 0
      @errors << "Tổng thu nhập phải lớn hơn 0."
    end
    
    # Validate số người phụ thuộc
    if params[:dependents].blank?
      @errors << "Vui lòng nhập số người phụ thuộc."
    elsif @dependents < 0
      @errors << "Số người phụ thuộc phải lớn hơn hoặc bằng 0."
    end
    
    # Validate khoản giảm trừ khác (nếu có)
    if params[:other_deductions].present? && @other_deductions < 0
      @errors << "Khoản giảm trừ khác phải lớn hơn hoặc bằng 0."
    end
    
    # Validate bảo hiểm bắt buộc (nếu có)
    if params[:insurance].present? && @insurance < 0
      @errors << "Bảo hiểm bắt buộc phải lớn hơn hoặc bằng 0."
    end
    
    @errors.empty?
  end
end
