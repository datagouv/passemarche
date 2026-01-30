# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin pages accessibility', type: :system do
  include Warden::Test::Helpers

  let(:admin) { create(:admin_user) }

  before do
    driven_by(:headless_chromium)
  end

  describe 'Admin login page' do
    it 'meets accessibility standards', :js do
      pending 'Known accessibility issues: page-has-heading-one (missing h1)'
      visit new_admin_user_session_path

      check_accessibility
    end
  end

  describe 'Admin editors list' do
    before do
      login_as(admin, scope: :admin_user)
    end

    it 'meets accessibility standards', :js do
      visit admin_editors_path

      check_accessibility
    end
  end

  describe 'Admin dashboard' do
    before do
      login_as(admin, scope: :admin_user)
    end

    it 'meets accessibility standards', :js do
      pending 'Known accessibility issues: heading structure needs review'
      visit admin_dashboard_path

      check_accessibility
    end
  end
end
