# frozen_string_literal: true

class GroupingMemberRemovalEmailComponent < ViewComponent::Base
  def initialize(market_name:, mandataire_name:)
    @market_name = market_name
    @mandataire_name = mandataire_name
  end

  def call
    render EmailComponent.new(EmailComponent::Content.new(
      title: t('grouping_member_removal_mailer.removed.title'),
      intro:
    ))
  end

  private

  def intro
    "#{removal_explanation}<br><br>" \
    "#{t('grouping_member_removal_mailer.removed.contact')}".html_safe
  end

  def removal_explanation
    t('grouping_member_removal_mailer.removed.intro',
      mandataire_name: "<strong>#{ERB::Util.html_escape(@mandataire_name)}</strong>",
      market_name: ERB::Util.html_escape(@market_name))
  end
end
