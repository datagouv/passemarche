# frozen_string_literal: true

module Candidate
  class ApplicationController < ::ApplicationController
    include Candidate::Authentication
    include Candidate::WebhookSubmission

    before_action :require_candidate_authentication
  end
end
