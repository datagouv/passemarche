# frozen_string_literal: true

class GroupingSubmissionWebhookJob < WebhookJob
  include WebhookSyncable

  private

  def find_entity(entity_id)
    Grouping.includes(grouping_members: { market_application: { lots: %i[market_type platform_market_type] } })
      .find(entity_id)
  end

  def entity_webhook_url(entity)
    entity.public_market.editor.completion_webhook_url
  end

  def entity_webhook_secret(entity)
    entity.public_market.editor.webhook_secret
  end

  def entity_payload(grouping)
    {
      event: 'grouping.submitted',
      timestamp: grouping.submitted_at.iso8601,
      submission_mode: grouping.submission_mode,
      market_identifier: grouping.public_market.identifier,
      grouping: {
        legal_type: grouping.legal_type,
        members: grouping.grouping_members.map { |member| member_payload(member) }
      }
    }
  end

  def member_payload(member)
    {
      role: member.role,
      company_name: member.company_name,
      siret: member.siret,
      status: member.status,
      market_application: member_application_payload(member.market_application)
    }
  end

  def member_application_payload(market_application)
    return nil if market_application.nil?

    {
      identifier: market_application.identifier,
      attestation_url: market_application.completed? ? attestation_url_for(market_application) : nil,
      documents_package_url: market_application.completed? ? documents_package_url_for(market_application) : nil,
      selected_lots: selected_lots_payload(market_application)
    }
  end

  def attestation_url_for(market_application)
    Rails.application.routes.url_helpers.attestation_api_v1_market_application_url(market_application.identifier)
  end

  def documents_package_url_for(market_application)
    Rails.application.routes.url_helpers.documents_package_api_v1_market_application_url(market_application.identifier)
  end

  def selected_lots_payload(market_application)
    market_application.lots.sort_by(&:position).map { |lot| lot_payload(lot) }
  end

  def lot_payload(lot)
    {
      id: lot.id,
      name: lot.name,
      cpv_code: lot.cpv_code,
      market_type_code: lot.effective_market_type&.code
    }
  end
end
