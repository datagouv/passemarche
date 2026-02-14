# frozen_string_literal: true

class Admin::AuditLogsController < Admin::ApplicationController
  include Pagy::Backend

  def index
    scope = filtered_versions
    @pagy, @versions = pagy(scope)
    @admin_users = AdminUser.all
  end

  def show
    @version = PaperTrail::Version.find(params[:id])
  end

  private

  def filtered_versions
    scope = PaperTrail::Version.where(item_type: 'MarketAttribute').order(created_at: :desc)
    if params[:query].present?
      scope = scope.where('item_id IN (SELECT id FROM market_attributes WHERE category_key ILIKE :q) OR ' \
                          'object_changes ILIKE :q',
        q: "%#{PaperTrail::Version.sanitize_sql_like(params[:query])}%")
    end
    scope = apply_date_filter(scope)
    scope = scope.where(whodunnit: params[:admin_user_id]) if params[:admin_user_id].present?
    scope
  end

  def apply_date_filter(scope)
    scope = scope.where(created_at: Date.parse(params[:date_from]).beginning_of_day..) if params[:date_from].present?
    scope = scope.where(created_at: ..Date.parse(params[:date_to]).end_of_day) if params[:date_to].present?
    scope
  end
end
