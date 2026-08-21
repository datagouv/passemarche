# frozen_string_literal: true

module Candidate
  module GroupingCompositionActions
    extend ActiveSupport::Concern

    included do
      skip_before_action :setup_wizard, only: %i[create_member destroy_member]
    end

    def create_member
      result = Candidate::AddGroupingMember.call(grouping:, siret: params[:siret], email: params[:email])
      assign_create_member_result(result)

      render turbo_stream: member_form_turbo_streams, status: result.success? ? :ok : :unprocessable_content
    end

    def destroy_member
      Candidate::RemoveGroupingMember.call(grouping:, grouping_member_id: params[:id])

      render turbo_stream: [
        turbo_stream.replace(
          'grouping_members_table',
          partial: 'candidate/grouping_wizard/members_table',
          locals: { grouping:, market_application: @market_application, editable: true }
        ),
        turbo_stream.replace(
          'grouping_composition_actions',
          partial: 'candidate/grouping_wizard/composition_actions',
          locals: { grouping: }
        )
      ]
    end

    private

    def show_grouping_composition
      resolve_mandataire_company_name
      @grouping = grouping
      @grouping_member = GroupingMember.new
    end

    def assign_create_member_result(result)
      if result.success?
        @grouping_member = GroupingMember.new
      else
        @grouping_member = grouping.grouping_members.new(siret: params[:siret], email: params[:email])
        @errors = result.errors
      end
    end

    def member_form_turbo_streams
      [
        turbo_stream.replace(
          'grouping_members_table',
          partial: 'candidate/grouping_wizard/members_table',
          locals: { grouping:, market_application: @market_application, editable: true }
        ),
        turbo_stream.replace(
          'grouping_member_form',
          partial: 'candidate/grouping_wizard/member_form',
          locals: { grouping:, market_application: @market_application, grouping_member: @grouping_member, errors: @errors }
        ),
        turbo_stream.replace(
          'grouping_composition_actions',
          partial: 'candidate/grouping_wizard/composition_actions',
          locals: { grouping: }
        )
      ]
    end

    def resolve_mandataire_company_name
      mandataire_member = grouping.grouping_members.mandataire.first
      return if mandataire_member.nil? || mandataire_member.company_name.present?

      result = FetchRaisonSociale.call(siret: mandataire_member.siret)
      mandataire_member.update(company_name: result.raison_sociale) if result.success?
    end
  end
end
