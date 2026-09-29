# frozen_string_literal: true

module Candidate
  module GroupingMemberGuard
    extend ActiveSupport::Concern

    included do
      prepend_before_action :find_market_application
      before_action :redirect_unless_grouping_member
    end

    private

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: "La candidature recherchée n'a pas été trouvée", status: :not_found
    end

    def redirect_unless_grouping_member
      return if current_grouping_member

      redirect_to application_mode_candidate_market_application_path(@market_application.identifier)
    end

    def current_grouping_member
      return @current_grouping_member if defined?(@current_grouping_member)

      @current_grouping_member = @market_application.grouping_member
    end

    def grouping
      return @grouping if defined?(@grouping)

      @grouping = current_grouping_member&.grouping
    end
  end
end
