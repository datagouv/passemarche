# frozen_string_literal: true

class Api::V1::BaseController < ActionController::API
  before_action :doorkeeper_authorize!

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: 'Resource not found' }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  private

  def current_editor
    @current_editor ||= Editor.find_by(client_id: doorkeeper_token.application.uid)
  end

  def doorkeeper_unauthorized_render_options(*)
    { json: { error: 'Not authorized' } }
  end

  def doorkeeper_forbidden_render_options(*)
    { json: { error: 'Forbidden' } }
  end
end
