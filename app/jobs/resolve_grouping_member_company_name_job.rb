# frozen_string_literal: true

class ResolveGroupingMemberCompanyNameJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(grouping_member_id)
    grouping_member = GroupingMember.find(grouping_member_id)
    return if grouping_member.company_name.present?

    result = FetchRaisonSociale.call(siret: grouping_member.siret)
    return unless result.success?

    grouping_member.update!(company_name: result.raison_sociale)
  rescue StandardError => e
    Sentry.capture_exception(e)
  end
end
