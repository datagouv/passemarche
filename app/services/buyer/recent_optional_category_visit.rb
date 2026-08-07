# frozen_string_literal: true

module Buyer
  class RecentOptionalCategoryVisit
    EXPIRY = 1.hour

    class << self
      def mark_visited(public_market, category_key)
        Rails.cache.write(cache_key(public_market, category_key), true, expires_in: EXPIRY)
      end

      def visited?(public_market, category_key)
        Rails.cache.exist?(cache_key(public_market, category_key))
      end

      private

      def cache_key(public_market, category_key)
        "buyer/recent_optional_category_visit/#{public_market.identifier}/#{category_key}"
      end
    end
  end
end
