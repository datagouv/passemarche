# frozen_string_literal: true

class SocleDeBaseStatsService < ApplicationService
  Stats = Struct.new(:total_count, :api_count, :manual_count, :mandatory_count, keyword_init: true)

  def call
    Stats.new(
      total_count:,
      api_count:,
      manual_count:,
      mandatory_count:
    )
  end

  private

  def total_count
    @total_count ||= MarketAttribute.active.count
  end

  def api_count
    @api_count ||= MarketAttribute.active.from_api.count
  end

  def manual_count
    total_count - api_count
  end

  def mandatory_count
    @mandatory_count ||= MarketAttribute.active.mandatory.count
  end
end
