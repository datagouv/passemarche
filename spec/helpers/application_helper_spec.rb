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
end
