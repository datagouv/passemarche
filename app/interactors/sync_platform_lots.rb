# frozen_string_literal: true

class SyncPlatformLots < ApplicationInteractor
  delegate :market_application, :lot_ids, to: :context

  def call
    return unlock_lots unless context.to_h.key?(:lot_ids)
    return unless context.application_mode.to_s == 'solo'
    return replace_lots if market_application.in_progress?

    refuse_lot_change_after_deadline
  end

  private

  def unlock_lots
    market_application.unlock_platform_lots! if market_application.lots_locked? && market_application.in_progress?
  end

  def replace_lots
    policy = LotSelectionPolicy.new(market_application, lot_ids)
    context.fail!(errors: { lot_ids: policy.errors.map(&:message) }) unless policy.valid?

    candidate_already_started = candidate_already_started?
    market_application.replace_lots_from_platform!(policy.lot_ids)
    Candidate::EnqueueApiDataFetch.call(market_application:) if candidate_already_started
  end

  def candidate_already_started?
    market_application.started_at? || market_application.api_fetch_status.present?
  end

  def refuse_lot_change_after_deadline
    policy = LotSelectionPolicy.new(market_application, lot_ids)
    return if policy.valid? && policy.lot_ids.sort == market_application.lot_ids.sort

    context.fail!(errors: { lot_ids: [I18n.t('api.errors.platform_lots_after_deadline')] })
  end
end
