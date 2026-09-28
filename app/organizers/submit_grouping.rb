# frozen_string_literal: true

class SubmitGrouping < ApplicationOrganizer
  organize MarkGroupingAsSubmitted,
    QueueGroupingSubmissionWebhook
end
