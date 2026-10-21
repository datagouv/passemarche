# frozen_string_literal: true

module Candidate
  module StatusPageApplication
    extend ActiveSupport::Concern

    included do
      prepend_before_action :find_market_application
    end

    private

    def find_market_application
      @market_application = MarketApplication
        .includes(public_market: :editor)
        .find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: "La candidature recherchée n'a pas été trouvée", status: :not_found
    end
  end
end
