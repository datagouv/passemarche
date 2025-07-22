# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      before_action :doorkeeper_authorize!

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
  end
end
