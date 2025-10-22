# frozen_string_literal: true

# Configure ActiveJob to perform jobs inline during Cucumber tests
# This ensures that when background jobs are triggered, they execute immediately
# before the next step runs

Before do
  # Use inline adapter to perform jobs immediately when enqueued
  ActiveJob::Base.queue_adapter = :inline
end
