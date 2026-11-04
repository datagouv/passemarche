# frozen_string_literal: true

module Candidate
  class ApplicationController < ::ApplicationController
    include Candidate::Authentication
    include Candidate::WebhookSubmission

    before_action :require_candidate_authentication
    before_action :set_paper_trail_whodunnit

    private

    def user_for_paper_trail
      ActionView::RecordIdentifier.dom_id(current_candidate) if current_candidate
    end
  end
end
