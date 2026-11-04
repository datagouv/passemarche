# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#page_break_class' do
    it 'returns page-break-before for pdf context when index is positive' do
      expect(helper.page_break_class(:pdf, 1)).to eq('page-break-before')
    end

    it 'returns page-break-before for buyer context when index is positive' do
      expect(helper.page_break_class(:buyer, 2)).to eq('page-break-before')
    end

    it 'returns nil for web context' do
      expect(helper.page_break_class(:web, 1)).to be_nil
    end

    it 'returns nil when index is zero' do
      expect(helper.page_break_class(:pdf, 0)).to be_nil
    end
  end

  describe '#collapsible_toggle_button' do
    it 'renders a button with the collapsible-list controller attributes' do
      result = helper.collapsible_toggle_button
      expect(result).to have_css('button.collapsible-list__toggle', visible: :all)
      expect(result).to have_css('[data-collapsible-list-target="toggle"]', visible: :all)
      expect(result).to have_css('[data-action="collapsible-list#toggle"]', visible: :all)
    end

    it 'wraps the button in a centered div by default' do
      result = helper.collapsible_toggle_button
      expect(result).to have_css('div.collapsible-list__toggle-wrapper')
      expect(result).not_to include('collapsible-list__toggle-wrapper--left')
    end

    it 'aligns left when align: :left is passed' do
      result = helper.collapsible_toggle_button(align: :left)
      expect(result).to have_css('div.collapsible-list__toggle-wrapper--left')
    end
  end
end
