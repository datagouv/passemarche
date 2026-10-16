# frozen_string_literal: true

class GroupingMemberCompletionEmailComponent < ViewComponent::Base
  def initialize(url:, market_name:, co_traitant_name:)
    @url = url
    @market_name = market_name
    @co_traitant_name = co_traitant_name
  end

  def call
    render EmailComponent.new(EmailComponent::Content.new(
      title: t('grouping_member_completion_mailer.completed.title'),
      intro:,
      cta_label: t('grouping_member_completion_mailer.completed.cta'),
      url: @url
    ))
  end

  private

  def intro
    "#{completion_explanation}<br><br>" \
    "#{t('grouping_member_completion_mailer.completed.dashboard_explanation')}".html_safe
  end

  def completion_explanation
    t('grouping_member_completion_mailer.completed.intro',
      co_traitant_name: "<strong>#{ERB::Util.html_escape(@co_traitant_name)}</strong>",
      market_name: ERB::Util.html_escape(@market_name))
  end
end
