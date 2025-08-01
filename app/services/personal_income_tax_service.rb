# frozen_string_literal: true

# Service tính thuế thu nhập cá nhân theo biểu thuế lũy tiến từng phần
# @author Cascade
# @since 2025-07-31
class PersonalIncomeTaxService
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
  def calculate
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
        tax_breakdown << {
          income_range: "#{previous_limit.to_i.to_s(:delimited)} - #{bracket[:limit] == Float::INFINITY ? 'trở lên' : bracket[:limit].to_i.to_s(:delimited)}",
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
