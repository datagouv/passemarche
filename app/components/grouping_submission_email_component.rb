# frozen_string_literal: true

class GroupingSubmissionEmailComponent < ViewComponent::Base
  def initialize(market_name:, mandataire_name:)
    @market_name = market_name
    @mandataire_name = mandataire_name
  end

  def call
    render EmailComponent.new(EmailComponent::Content.new(
      title: t('grouping_submission_mailer.submitted.title'),
      intro:,
      notice: t('grouping_submission_mailer.submitted.locked_notice')
    ))
  end

  private

  def intro
    "#{market_introduction}<br><br>" \
    "#{t('grouping_submission_mailer.submitted.inclusion')}".html_safe
  end

  def market_introduction
    t('grouping_submission_mailer.submitted.intro',
      mandataire_name: "<strong>#{ERB::Util.html_escape(@mandataire_name)}</strong>",
      market_name: ERB::Util.html_escape(@market_name))
  end
end
