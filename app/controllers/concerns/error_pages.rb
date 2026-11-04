# frozen_string_literal: true

module ErrorPages
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_record_not_found
    rescue_from Wicked::Wizard::InvalidStepError, with: :render_invalid_step
  end

  private

  def render_error_page(error_page, status:)
    return head(status) unless request.format.html?

    I18n.with_locale(extract_locale) do
      render 'errors/show', locals: { error_page: }, status:
    end
  end

  def render_record_not_found(exception)
    render_error_page(record_not_found_page(exception.model), status: :not_found)
  end

  def render_invalid_step
    render_error_page(:not_found, status: :not_found)
  end

  def record_not_found_page(model_name)
    error_page = :"#{model_name.to_s.underscore}_not_found"
    I18n.exists?("errors.pages.#{error_page}") ? error_page : :not_found
  end
end
