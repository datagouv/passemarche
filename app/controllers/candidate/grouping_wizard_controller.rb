# frozen_string_literal: true

module Candidate
  class GroupingWizardController < Candidate::ApplicationController
    include Wicked::Wizard
    include Candidate::GroupementFeatureGuard
    include Candidate::MarketApplicationGuard

    rescue_from Wicked::Wizard::InvalidStepError, with: :redirect_to_application_mode

    prepend_before_action :set_steps
    prepend_before_action :find_market_application
    before_action :redirect_unless_mandataire, unless: -> { params[:id] == 'application_mode' }

    def show
      case step
      when :application_mode then show_application_mode
      when :grouping_legal_type then show_grouping_legal_type
      end

      render_wizard unless performed?
    end

    def update
      case step
      when :application_mode then update_application_mode
      when :grouping_legal_type then update_grouping_legal_type
      end
    end

    private

    def set_steps
      self.steps = if @market_application&.groupement?
                     %i[application_mode grouping_legal_type]
                   else
                     %i[application_mode]
                   end
    end

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: "La candidature recherchée n'a pas été trouvée", status: :not_found
    end

    def finish_wizard_path
      company_identification_candidate_market_application_path(@market_application.identifier)
    end

    def redirect_to_application_mode
      redirect_to grouping_wizard_step_candidate_market_application_path(@market_application.identifier, :application_mode)
    end

    def redirect_unless_mandataire
      return if grouping

      redirect_to_application_mode
    end

    def next_wizard_step_path(from_step)
      counterpart = @market_application.groupement_counterpart
      return counterpart_next_wizard_step_path(counterpart) if counterpart

      next_real_step = next_step(from_step)
      return finish_wizard_path if next_real_step == Wicked::FINISH_STEP

      wizard_step_path(@market_application, next_real_step)
    end

    def counterpart_next_wizard_step_path(counterpart)
      return wizard_step_path(counterpart, :grouping_legal_type) if counterpart.grouping_legal_type_choice_required?

      finish_wizard_path
    end

    def wizard_step_path(market_application, step)
      grouping_wizard_step_candidate_market_application_path(market_application.identifier, step)
    end

    # --- application_mode step ---

    def show_application_mode
      return redirect_to(next_wizard_step_path(:application_mode)) if @market_application.application_mode.present? && !params[:readonly]

      @already_mandataire = already_mandataire_elsewhere?
      @readonly = @market_application.application_mode.present?
      @readonly_continue_path = readonly_continue_path if @readonly
    end

    def readonly_continue_path
      next_wizard_step_path(:application_mode)
    end

    def update_application_mode
      result = Candidate::CreateApplicationsForMode.call(
        market_application: @market_application,
        application_mode: params[:application_mode]
      )

      return handle_application_mode_success(result) if result.success?

      @already_mandataire = already_mandataire_elsewhere?
      @errors = result.errors
      render_wizard(nil, status: :unprocessable_content)
    end

    def handle_application_mode_success(result)
      @market_application = result.market_application
      set_steps
      redirect_to next_wizard_step_path(:application_mode)
    end

    def already_mandataire_elsewhere?
      Grouping
        .joins(:mandataire_market_application)
        .where(public_market: @market_application.public_market, market_applications: { siret: @market_application.siret })
        .where.not(market_applications: { id: @market_application.id })
        .exists?
    end

    # --- grouping_legal_type step ---

    def show_grouping_legal_type
      @grouping = grouping
    end

    def update_grouping_legal_type
      result = Candidate::SetGroupingLegalType.call(
        market_application: @market_application,
        legal_type: params[:legal_type]
      )

      if result.success?
        redirect_to next_wizard_step_path(:grouping_legal_type)
      else
        @grouping = grouping
        @errors = result.errors
        render_wizard(nil, status: :unprocessable_content)
      end
    end

    def grouping
      return @grouping if defined?(@grouping)

      @grouping = Grouping.joins(:mandataire_market_application).find_by(market_applications: { id: @market_application.id })
    end
  end
end
