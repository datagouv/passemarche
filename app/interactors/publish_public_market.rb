# frozen_string_literal: true

class PublishPublicMarket < ApplicationInteractor
  delegate :public_market, to: :context

  def call
    context.fail!(errors: { base: [I18n.t('api.errors.market_not_completed')] }) unless public_market.completed?
    context.fail!(errors: { base: [I18n.t('api.errors.market_already_published')] }) if public_market.published?

    public_market.publish!
  end
end
