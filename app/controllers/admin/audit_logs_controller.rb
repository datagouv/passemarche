# frozen_string_literal: true

class Admin::AuditLogsController < Admin::ApplicationController
  include Pagy::Backend

  def index
    @filter_params = filter_params
    scope = filtered_versions
    @pagy, @versions = pagy(scope)
    @admin_users = AdminUser.all
  end

  def show
    @version = PaperTrail::Version.find(params[:id])
  end

  private

  def filter_params
    params.permit(:query, :date_from, :date_to, :admin_user_id)
  end

  def filtered_versions
    scope = PaperTrail::Version.where(item_type: 'MarketAttribute').order(created_at: :desc)
    scope = apply_query_filter(scope)
    scope = apply_date_filter(scope)
    scope = scope.where(whodunnit: @filter_params[:admin_user_id]) if @filter_params[:admin_user_id].present?
    scope
  end

  def apply_query_filter(scope)
    return scope if @filter_params[:query].blank?

    sanitized = "%#{PaperTrail::Version.sanitize_sql_like(@filter_params[:query])}%"
    matching_ids = MarketAttribute.where(MarketAttribute.arel_table[:category_key].matches(sanitized)).select(:id)
    scope.where(item_id: matching_ids).or(
      scope.where(PaperTrail::Version.arel_table[:object_changes].matches(sanitized))
    )
  end

  def apply_date_filter(scope)
    scope = scope.where(created_at: Date.parse(@filter_params[:date_from]).beginning_of_day..) if @filter_params[:date_from].present?
    scope = scope.where(created_at: ..Date.parse(@filter_params[:date_to]).end_of_day) if @filter_params[:date_to].present?
    scope
  end
end
