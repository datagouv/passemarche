# frozen_string_literal: true

class GroupingMemberCompletionEmailComponent < ViewComponent::Base
  def initialize(url:, market_name:, co_traitant_name:, event: :completed)
    @url = url
    @event = event
    @market_name = market_name
    @co_traitant_name = co_traitant_name
  end

  def call
    render EmailComponent.new(EmailComponent::Content.new(
      title: t('title', scope: event_scope),
      intro:,
      cta_label: t('grouping_member_completion_mailer.cta'),
      url: @url
    ))
  end

  private

  def event_scope
    "grouping_member_completion_mailer.#{@event}"
  end

  def intro
    "#{completion_explanation}<br><br>" \
    "#{t('grouping_member_completion_mailer.dashboard_explanation')}".html_safe
  end

  def completion_explanation
    t('intro', scope: event_scope,
      co_traitant_name: "<strong>#{ERB::Util.html_escape(@co_traitant_name)}</strong>",
      market_name: ERB::Util.html_escape(@market_name))
  end
end
