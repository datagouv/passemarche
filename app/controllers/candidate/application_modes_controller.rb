# frozen_string_literal: true

module Candidate
  class ApplicationModesController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MarketApplicationGuard
    include Candidate::WizardRoutable

    prepend_before_action :find_market_application
    before_action :redirect_if_mode_already_chosen

    def show
      @already_mandataire = already_mandataire_elsewhere?
      @readonly = @market_application.application_mode.present?
      @readonly_continue_path = next_required_wizard_step_path(@market_application) if @readonly
    end

    def update
      result = Candidate::CreateApplicationsForMode.call(
        market_application: @market_application,
        application_mode: params[:application_mode]
      )

      return handle_success(result) if result.success?

      @already_mandataire = already_mandataire_elsewhere?
      @errors = result.errors
      render :show, status: :unprocessable_content
    end

    private

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: "La candidature recherchée n'a pas été trouvée", status: :not_found
    end

    def redirect_if_mode_already_chosen
      return if @market_application.application_mode.nil?
      return if action_name == 'show' && params[:readonly].present?

      redirect_to next_required_wizard_step_path(@market_application)
    end

    def already_mandataire_elsewhere?
      Grouping
        .joins(:mandataire_market_application)
        .where(public_market: @market_application.public_market, market_applications: { siret: @market_application.siret })
        .where.not(market_applications: { id: @market_application.id })
        .exists?
    end

    def handle_success(result)
      redirect_to next_required_wizard_step_path(result.market_application)
    end
  end
end
