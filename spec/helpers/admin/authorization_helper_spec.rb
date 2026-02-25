# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::AuthorizationHelper, type: :helper do
  describe '#admin_action_link_to' do
    context 'when user can modify' do
      before do
        val = true
        helper.define_singleton_method(:current_user_can_modify?) { val }
      end

      it 'renders a link' do
        result = helper.admin_action_link_to('Edit', '/edit', class: 'fr-btn')
        expect(result).to have_link('Edit', href: '/edit')
        expect(result).to have_css('a.fr-btn')
      end
    end

    context 'when user cannot modify' do
      before do
        val = false
        helper.define_singleton_method(:current_user_can_modify?) { val }
      end

      it 'renders a disabled button' do
        result = helper.admin_action_link_to('Edit', '/edit', class: 'fr-btn')
        expect(result).to have_css('button.fr-btn[disabled]')
        expect(result).to have_button('Edit', disabled: true)
      end

      it 'does not render a link' do
        result = helper.admin_action_link_to('Edit', '/edit', class: 'fr-btn')
        expect(result).not_to have_link('Edit')
      end
    end
  end
end
