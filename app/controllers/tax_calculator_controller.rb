# frozen_string_literal: true

class TaxCalculatorController < ApplicationController
  # Include NumberHelper để sử dụng number_with_delimiter
  include ActionView::Helpers::NumberHelper
  def index
    # Chuyển hướng về trang chủ
    redirect_to root_path
  end

  def calculate
    @income = params[:income].present? ? params[:income].to_f : 0
    @dependents = params[:dependents].present? ? params[:dependents].to_i : 0
    @other_deductions = params[:other_deductions].present? ? params[:other_deductions].to_f : 0
    @insurance = params[:insurance].present? ? params[:insurance].to_f : 0

    # Validate dữ liệu đầu vào
    if validate_input
      # Tạo một instance của TaxCalculator để tính thuế
      calculator = TaxCalculator.new(
        income: @income,
        dependents: @dependents,
        other_deductions: @other_deductions,
        insurance: @insurance
      )
      
      # Tính thuế và lấy kết quả
      @tax_result = calculator.calculate_tax
      @tax_details = calculator.tax_details
      
      # Sử dụng flash để lưu dữ liệu cho request tiếp theo
      flash[:tax_result] = @tax_result
      flash[:tax_details] = @tax_details
      flash[:tax_inputs] = {
        income: @income,
        dependents: @dependents,
        other_deductions: @other_deductions,
        insurance: @insurance
      }
      
      # Đảm bảo flash được lưu trước khi chuyển hướng
      redirect_to root_path(show_tax_result: true)
    else
      # Lưu lỗi và chuyển hướng về trang chủ
      flash[:errors] = @errors
      redirect_to root_path
    end
  end
  
  # Lớp TaxCalculator để tính thuế thu nhập cá nhân
  class TaxCalculator
    # Mức giảm trừ gia cảnh cá nhân (VND/tháng)
    PERSONAL_DEDUCTION = 11_000_000
    
    # Mức giảm trừ cho mỗi người phụ thuộc (VND/tháng)
    DEPENDENT_DEDUCTION = 4_400_000
    
    # Biểu thuế lũy tiến từng phần theo quy định hiện hành
    TAX_BRACKETS = [
      { limit: 5_000_000, rate: 0.05 },
      { limit: 10_000_000, rate: 0.10 },
      { limit: 18_000_000, rate: 0.15 },
      { limit: 32_000_000, rate: 0.20 },
      { limit: 52_000_000, rate: 0.25 },
      { limit: 80_000_000, rate: 0.30 },
      { limit: Float::INFINITY, rate: 0.35 }
    ]
    
    attr_reader :income, :dependents, :other_deductions, :insurance, :tax_details
    
    # @param income [Float] Tổng thu nhập/tháng
    # @param dependents [Integer] Số người phụ thuộc
    # @param other_deductions [Float] Khoản giảm trừ khác (tùy chọn)
    # @param insurance [Float] Bảo hiểm bắt buộc (tùy chọn)
    def initialize(income:, dependents:, other_deductions: 0, insurance: 0)
      @income = income
      @dependents = dependents
      @other_deductions = other_deductions
      @insurance = insurance
      @tax_details = {}
    end
    
    # Tính thuế thu nhập cá nhân
    # @return [Float] Số tiền thuế phải nộp
    def calculate_tax
      # Tính tổng các khoản giảm trừ
      total_deductions = calculate_total_deductions
      
      # Tính thu nhập chịu thuế
      taxable_income = [@income - total_deductions, 0].max
      
      # Tính thuế theo biểu thuế lũy tiến từng phần
      calculate_progressive_tax(taxable_income)
    end
    
    private
    
    # Tính tổng các khoản giảm trừ
    # @return [Float] Tổng các khoản giảm trừ
    def calculate_total_deductions
      # Giảm trừ gia cảnh cá nhân
      personal_deduction = PERSONAL_DEDUCTION
      
      # Giảm trừ người phụ thuộc
      dependent_deduction = @dependents * DEPENDENT_DEDUCTION
      
      # Tổng các khoản giảm trừ
      total = personal_deduction + dependent_deduction + @other_deductions + @insurance
      
      # Lưu chi tiết các khoản giảm trừ
      @tax_details[:deductions] = {
        personal: personal_deduction,
        dependent: dependent_deduction,
        other: @other_deductions,
        insurance: @insurance,
        total: total
      }
      
      total
    end
    
    # Tính thuế theo biểu thuế lũy tiến từng phần
    # @param taxable_income [Float] Thu nhập chịu thuế
    # @return [Float] Số tiền thuế phải nộp
    def calculate_progressive_tax(taxable_income)
      return 0 if taxable_income <= 0
      
      remaining_income = taxable_income
      total_tax = 0
      tax_breakdown = []
      previous_limit = 0
      
      TAX_BRACKETS.each do |bracket|
        bracket_income = [remaining_income, bracket[:limit] - previous_limit].min
        bracket_tax = bracket_income * bracket[:rate]
        
        if bracket_income > 0
          # Tránh sử dụng các phương thức định dạng số phức tạp
          prev_limit_str = previous_limit.to_i.to_s
          limit_str = bracket[:limit] == Float::INFINITY ? 'trở lên' : bracket[:limit].to_i.to_s
          
          tax_breakdown << {
            income_range: "#{prev_limit_str} - #{limit_str}",
            rate: (bracket[:rate] * 100).to_i,
            taxable_amount: bracket_income,
            tax: bracket_tax
          }
        end
        
        total_tax += bracket_tax
        remaining_income -= bracket_income
        previous_limit = bracket[:limit]
        
        break if remaining_income <= 0
      end
      
      # Lưu chi tiết tính thuế
      @tax_details[:calculation] = {
        income: @income,
        taxable_income: taxable_income,
        tax_breakdown: tax_breakdown,
        total_tax: total_tax
      }
      
      total_tax
    end
  end

  private

  # Kiểm tra tính hợp lệ của dữ liệu đầu vào
  #
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
