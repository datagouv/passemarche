# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Public pages accessibility', type: :system do
  before do
    driven_by(:headless_chromium)
  end

  describe 'Home page' do
    it 'meets accessibility standards', :js do
      pending 'Known accessibility issues: heading-order (h4 used without h2/h3)'
      visit root_path

      check_accessibility
    end
  end

  describe 'Candidate home page' do
    it 'meets accessibility standards', :js do
      visit candidate_home_path

      check_accessibility
    end
  end

  describe 'Buyer home page' do
    it 'meets accessibility standards', :js do
      pending 'Known accessibility issues: heading structure needs review'
      visit buyer_home_path

      check_accessibility
    end
  end
end
