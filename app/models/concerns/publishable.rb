# frozen_string_literal: true

module Publishable
  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.zone.now)
  end
end
