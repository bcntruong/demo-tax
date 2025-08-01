# frozen_string_literal: true

# @author Cascade
# @since 2025-08-01
class TaxCalculatorController < ApplicationController
  def index
    redirect_to root_path
  end

  def calculate
    @income = params[:income].present? ? params[:income].to_f : 0
    @dependents = params[:dependents].present? ? params[:dependents].to_i : 0
    @other_deductions = params[:other_deductions].present? ? params[:other_deductions].to_f : 0
    @insurance = params[:insurance].present? ? params[:insurance].to_f : 0

    if validate_input
      tax_service = PersonalIncomeTaxService.new(
        income: @income,
        dependents: @dependents,
        other_deductions: @other_deductions,
        insurance: @insurance
      )
      
      @tax_result = tax_service.calculate
      @tax_details = tax_service.tax_details
      
      flash[:tax_result] = @tax_result
      flash[:tax_details] = @tax_details
      flash[:income] = @income
      flash[:dependents] = @dependents
      flash[:other_deductions] = @other_deductions
      flash[:insurance] = @insurance
      
      redirect_to root_path(show_tax_result: true)
    else
      flash[:errors] = @errors
      redirect_to root_path
    end
  end

  private

  def validate_input
    @errors = []
    
    if params[:income].blank?
      @errors << "Vui lòng nhập tổng thu nhập."
    elsif @income <= 0
      @errors << "Tổng thu nhập phải lớn hơn 0."
    end
    
    if params[:dependents].blank?
      @errors << "Vui lòng nhập số người phụ thuộc."
    elsif @dependents < 0
      @errors << "Số người phụ thuộc phải lớn hơn hoặc bằng 0."
    end
    
    if params[:other_deductions].present? && @other_deductions < 0
      @errors << "Khoản giảm trừ khác phải lớn hơn hoặc bằng 0."
    end
    
    if params[:insurance].present? && @insurance < 0
      @errors << "Bảo hiểm bắt buộc phải lớn hơn hoặc bằng 0."
    end
    
    @errors.empty?
  end
end
