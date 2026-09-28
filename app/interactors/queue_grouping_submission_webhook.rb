# frozen_string_literal: true

class QueueGroupingSubmissionWebhook < ApplicationInteractor
  delegate :grouping, to: :context

  def call
    GroupingSubmissionWebhookJob.perform_later(grouping.id)
  end
end
