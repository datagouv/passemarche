# frozen_string_literal: true

module Admin
  module Authorization
    extend ActiveSupport::Concern

    included do
      include Pundit::Authorization

      helper_method :current_user_can_modify?
    end

    private

    def pundit_user
      current_admin_user
    end

    def require_admin_role!
      return if current_admin_user&.admin?

      redirect_to admin_root_path, alert: I18n.t('admin.authorization.insufficient_permissions')
    end

    def current_user_can_modify?
      current_admin_user&.can_modify?
    end
  end
end
