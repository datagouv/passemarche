# frozen_string_literal: true

# Use inline adapter so jobs (emails, API calls) execute immediately during Cucumber scenarios.
# Individual jobs are tested in isolation via their own specs.

Before do
  ActiveJob::Base.queue_adapter = :inline
end
