# frozen_string_literal: true

module Candidate
  class GroupingCompositionsController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MarketApplicationGuard
    include Candidate::MandataireGroupingGuard
    include Candidate::WizardRoutable

    before_action :redirect_unless_legal_type_set

    def show
      enqueue_pending_company_name_resolutions
      @grouping = grouping
      @grouping_member = GroupingMember.new

      respond_to do |format|
        format.html
        format.json do
          set_no_cache_headers
          render json: { company_names_pending: company_names_pending? }
        end
      end
    end

    def create_member
      result = Candidate::AddGroupingMember.call(grouping:, siret: member_params[:siret], email: member_params[:email])
      assign_create_member_result(result)

      render turbo_stream: member_form_turbo_streams, status: result.success? ? :ok : :unprocessable_content
    end

    def destroy_member
      result = Candidate::RemoveGroupingMember.call(grouping:, grouping_member_id: params[:id])

      render turbo_stream: destroy_member_turbo_streams(result), status: destroy_member_status(result)
    end

    private

    def destroy_member_status(result)
      return :ok if result.success?
      return :not_found if result.not_found

      :unprocessable_content
    end

    def redirect_unless_legal_type_set
      return if grouping.legal_type.present?

      redirect_to grouping_legal_type_candidate_market_application_path(@market_application.identifier)
    end

    def member_params
      params.permit(:siret, :email)
    end

    def enqueue_pending_company_name_resolutions
      grouping.grouping_members.where(company_name: nil).find_each do |member|
        ResolveGroupingMemberCompanyNameJob.perform_later(member.id)
      end
    end

    def company_names_pending?
      grouping.grouping_members.exists?(company_name: nil)
    end

    def assign_create_member_result(result)
      if result.success?
        @grouping_member = GroupingMember.new
      else
        @grouping_member = grouping.grouping_members.new(siret: member_params[:siret], email: member_params[:email])
        @errors = result.errors
      end
    end

    def member_form_turbo_streams
      [
        turbo_stream.replace(
          'grouping_members_table',
          partial: 'candidate/grouping_compositions/members_table',
          locals: { grouping:, market_application: @market_application, editable: true }
        ),
        turbo_stream.replace(
          'grouping_member_form',
          partial: 'candidate/grouping_compositions/member_form',
          locals: { grouping:, market_application: @market_application, grouping_member: @grouping_member, errors: @errors }
        ),
        turbo_stream.replace(
          'grouping_composition_actions',
          partial: 'candidate/grouping_compositions/composition_actions',
          locals: { grouping: }
        )
      ]
    end

    def destroy_member_turbo_streams(result)
      return failed_destroy_member_turbo_streams(result) unless result.success?

      [
        turbo_stream.replace(
          'grouping_members_table',
          partial: 'candidate/grouping_compositions/members_table',
          locals: { grouping:, market_application: @market_application, editable: true }
        ),
        turbo_stream.replace(
          'grouping_composition_actions',
          partial: 'candidate/grouping_compositions/composition_actions',
          locals: { grouping: }
        )
      ]
    end

    def failed_destroy_member_turbo_streams(result)
      [
        turbo_stream.replace(
          "grouping_member_removal_errors_#{params[:id]}",
          partial: 'candidate/grouping_compositions/removal_errors',
          locals: { errors: result.errors, member_id: params[:id] }
        )
      ]
    end
  end
end
