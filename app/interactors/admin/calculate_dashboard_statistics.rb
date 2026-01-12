# frozen_string_literal: true

class Admin::CalculateDashboardStatistics < ApplicationInteractor
  def call
    context.statistics = {
      editors_total: calculate_editors_total,
      editors_active: calculate_editors_active,
      markets_total: calculate_markets_total,
      markets_completed: calculate_markets_completed,
      markets_active: calculate_markets_active,
      applications_total: calculate_applications_total,
      applications_completed: calculate_applications_completed,
      documents_transmitted: calculate_documents_transmitted,
      unique_companies: calculate_unique_companies,
      unique_buyers: calculate_unique_buyers,
      avg_completion_time_seconds: calculate_avg_completion_time,
      auto_fill_rate: calculate_auto_fill_rate
    }
  end

  private

  def editor
    context.editor
  end

  def scoped?
    editor.present?
  end

  def calculate_editors_total
    Editor.count
  end

  def calculate_editors_active
    Editor.authorized_and_active.count
  end

  def calculate_markets_total
    markets_scope.count
  end

  def calculate_markets_completed
    markets_scope.where.not(completed_at: nil).count
  end

  def calculate_markets_active
    markets_scope.where(completed_at: nil).count
  end

  def calculate_applications_total
    applications_scope.count
  end

  def calculate_applications_completed
    applications_scope.where.not(completed_at: nil).count
  end

  def calculate_documents_transmitted
    responses_scope.with_file_attachments.count
  end

  def calculate_unique_companies
    applications_scope.distinct.count(:siret)
  end

  def calculate_unique_buyers
    markets_scope.distinct.count(:siret)
  end

  def calculate_avg_completion_time
    timestamps = applications_scope
      .where.not(completed_at: nil)
      .pluck(:created_at, :completed_at)

    return nil if timestamps.empty?

    total_seconds = timestamps.sum { |created, completed| completed - created }
    total_seconds / timestamps.size
  end

  def calculate_auto_fill_rate
    total_responses = responses_scope.count
    return nil if total_responses.zero?

    auto_responses = responses_scope.where(source: :auto).count
    auto_responses.to_f / total_responses
  end

  def markets_scope
    scoped? ? PublicMarket.where(editor:) : PublicMarket.all
  end

  def applications_scope
    scoped? ? MarketApplication.joins(:public_market).where(public_markets: { editor_id: editor.id }) : MarketApplication.all
  end

  def responses_scope
    if scoped?
      MarketAttributeResponse
        .joins(market_application: :public_market)
        .where(public_markets: { editor_id: editor.id })
    else
      MarketAttributeResponse.all
    end
  end
end
